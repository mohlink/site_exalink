<?php
declare(strict_types=1);

/**
 * EXALINK: persistent per-IP contact submission limiter.
 * Limits valid SMTP submission attempts, not page views or CSRF token reads.
 * No raw IPs, message bodies, SMTP credentials or personally identifying
 * details are persisted. Keep the backing directory outside public_html.
 */
function enforce_rate_limit(string $privateDirectory, int $now, string $secret): void
{
    $remote = (string) ($_SERVER['REMOTE_ADDR'] ?? '');
    if (!filter_var($remote, FILTER_VALIDATE_IP) || $secret === '') {
        response(503, ['ok' => false, 'error' => 'rate_limit_unavailable']);
    }

    $folder = $privateDirectory . '/rate_limits';
    if (!is_dir($folder) && !@mkdir($folder, 0700, true) && !is_dir($folder)) {
        response(503, ['ok' => false, 'error' => 'rate_limit_unavailable']);
    }
    @chmod($folder, 0700);

    $key = hash_hmac('sha256', $remote, $secret);
    $path = $folder . '/' . $key . '.json';

    $oldUmask = umask(0077);
    $handle = @fopen($path, 'c+');
    umask($oldUmask);
    if ($handle === false) {
        response(503, ['ok' => false, 'error' => 'rate_limit_unavailable']);
    }
    @chmod($path, 0600);
    if (!flock($handle, LOCK_EX)) {
        fclose($handle);
        response(503, ['ok' => false, 'error' => 'rate_limit_unavailable']);
    }
    try {
        rewind($handle);
        $raw = stream_get_contents($handle, 4096);
        $history = [];
        if (is_string($raw) && $raw !== '') {
            $stored = json_decode($raw, true);
            if (!is_array($stored)) {
                response(503, ['ok' => false, 'error' => 'rate_limit_unavailable']);
            }
            foreach ($stored as $timestamp) {
                if (is_int($timestamp) && $timestamp > $now - 86400 && $timestamp <= $now + 60) {
                    $history[] = $timestamp;
                }
            }
        }

        $recent = array_filter($history, static fn(int $t): bool => $t > $now - 900);
        if (count($recent) >= 5 || count($history) >= 20) {
            header('Retry-After: 900');
            response(429, ['ok' => false, 'error' => 'slow_down']);
        }

        $history[] = $now;
        $encoded = json_encode($history);
        if (!is_string($encoded) || !ftruncate($handle, 0) || !rewind($handle)
            || fwrite($handle, $encoded) !== strlen($encoded) || !fflush($handle)) {
            response(503, ['ok' => false, 'error' => 'rate_limit_unavailable']);
        }
    } finally {
        flock($handle, LOCK_UN);
        fclose($handle);
    }
}
