<?php
declare(strict_types=1);

/* EXALINK — Funio-only endpoint. Do not use with GitHub Pages. */
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, max-age=0');
header('X-Content-Type-Options: nosniff');

function response(int $status, array $body): never {
    http_response_code($status);
    echo json_encode($body, JSON_UNESCAPED_UNICODE);
    exit;
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
    header('Allow: GET');
    response(405, ['ok' => false, 'error' => 'method_not_allowed']);
}
if (($_SERVER['HTTPS'] ?? 'off') === 'off' && ($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') !== 'https') {
    response(403, ['ok' => false, 'error' => 'https_required']);
}
ini_set('session.use_strict_mode', '1');
session_name('EXALINKCONTACT');
session_set_cookie_params([
    'lifetime' => 0,
    'path' => '/',
    'secure' => true,
    'httponly' => true,
    'samesite' => 'Strict',
]);
if (!session_start()) {
    response(503, ['ok' => false, 'error' => 'session_unavailable']);
}
$_SESSION['contact_token'] = bin2hex(random_bytes(32));
$_SESSION['contact_started'] = time();
response(200, ['ok' => true, 'token' => $_SESSION['contact_token']]);
