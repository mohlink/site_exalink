<?php
declare(strict_types=1);

/* EXALINK contact endpoint for PHP hosting. SMTP secrets stay outside the public web root.
   Requires PHPMailer and EXALINK_CONFIG_PATH, configured only on Funio. */
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, max-age=0');
header('X-Content-Type-Options: nosniff');

function response(int $status, array $body): never {
    http_response_code($status);
    echo json_encode($body, JSON_UNESCAPED_UNICODE);
    exit;
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    header('Allow: POST');
    response(405, ['ok' => false, 'error' => 'method_not_allowed']);
}
if (($_SERVER['HTTPS'] ?? 'off') === 'off' && ($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') !== 'https') {
    response(403, ['ok' => false, 'error' => 'https_required']);
}
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($origin !== '') {
    $originHost = parse_url($origin, PHP_URL_HOST);
    $host = explode(':', (string) ($_SERVER['HTTP_HOST'] ?? ''))[0];
    if (!is_string($originHost) || strcasecmp($originHost, $host) !== 0 || parse_url($origin, PHP_URL_SCHEME) !== 'https') {
        response(403, ['ok' => false, 'error' => 'origin_not_allowed']);
    }
}
$contentType = strtolower(trim(explode(';', (string) ($_SERVER['CONTENT_TYPE'] ?? ''))[0]));
if ($contentType !== 'application/json') {
    response(415, ['ok' => false, 'error' => 'json_required']);
}
if ((int) ($_SERVER['CONTENT_LENGTH'] ?? 0) > 16000) {
    response(413, ['ok' => false, 'error' => 'request_too_large']);
}
$raw = file_get_contents('php://input');
if (!is_string($raw) || strlen($raw) > 16000) {
    response(413, ['ok' => false, 'error' => 'request_too_large']);
}
try {
    $data = json_decode($raw, true, 12, JSON_THROW_ON_ERROR);
} catch (JsonException $error) {
    response(400, ['ok' => false, 'error' => 'bad_json']);
}
if (!is_array($data)) {
    response(400, ['ok' => false, 'error' => 'bad_json']);
}
ini_set('session.use_strict_mode', '1');
session_name('EXALINKCONTACT');
session_set_cookie_params([
    'lifetime' => 0, 'path' => '/', 'secure' => true,
    'httponly' => true, 'samesite' => 'Strict',
]);
if (!session_start()) {
    response(503, ['ok' => false, 'error' => 'session_unavailable']);
}
$token = $data['token'] ?? null;
$expected = $_SESSION['contact_token'] ?? null;
$started = (int) ($_SESSION['contact_started'] ?? 0);
$now = time();
if (!is_string($token) || !is_string($expected) || !hash_equals($expected, $token)
    || $started === 0 || $now - $started < 3 || $now - $started > 7200) {
    response(403, ['ok' => false, 'error' => 'expired_or_invalid_session']);
}
if (!empty($data['website'])) {
    response(400, ['ok' => false, 'error' => 'invalid_request']);
}
if ($now - (int) ($_SESSION['last_contact_sent'] ?? 0) < 60) {
    response(429, ['ok' => false, 'error' => 'slow_down']);
}
function clean(array $data, string $name, int $limit, bool $multiline = false): string {
    $value = $data[$name] ?? '';
    if (!is_string($value)) {
        return '';
    }
    $value = trim(strip_tags($value));
    $value = str_replace(["\r\n", "\r"], "\n", $value);
    if (!$multiline) {
        $value = preg_replace('/\s+/u', ' ', $value) ?? '';
    }
    return mb_strlen($value, 'UTF-8') <= $limit ? $value : '';
}
$name = clean($data, 'name', 120);
$company = clean($data, 'company', 160);
$email = clean($data, 'email', 180);
$phone = clean($data, 'phone', 50);
$message = clean($data, 'message', 4000, true);
$area = $data['subject'] ?? '';
$areas = [
    'it' => 'IT / Networking',
    'telecom' => 'Telecommunications / LTE / 5G / Wi-Fi',
    'integration' => 'Smart Systems / Integration',
    'other' => 'Other technology project',
];
if ($name === '' || $message === '' || mb_strlen($message, 'UTF-8') < 12
    || !filter_var($email, FILTER_VALIDATE_EMAIL)
    || !is_string($area) || !isset($areas[$area])) {
    response(422, ['ok' => false, 'error' => 'invalid_fields']);
}
$configurationPath = getenv('EXALINK_CONFIG_PATH');
if (!is_string($configurationPath) || $configurationPath === ''
    || !is_readable($configurationPath)) {
    response(503, ['ok' => false, 'error' => 'mail_not_configured']);
}
$settings = require $configurationPath;
if (!is_array($settings)) {
    response(503, ['ok' => false, 'error' => 'mail_not_configured']);
}
$required = ['autoload', 'smtp_host', 'smtp_port', 'smtp_username', 'smtp_password', 'smtp_encryption', 'from_email', 'from_name', 'to_email'];
foreach ($required as $key) {
    if (!isset($settings[$key]) || (string) $settings[$key] === '') {
        response(503, ['ok' => false, 'error' => 'mail_not_configured']);
    }
}
if (!is_readable((string) $settings['autoload'])) {
    response(503, ['ok' => false, 'error' => 'mail_not_configured']);
}
require_once (string) $settings['autoload'];
try {
    $mail = new PHPMailer\PHPMailer\PHPMailer(true);
    $mail->isSMTP();
    $mail->Host = (string) $settings['smtp_host'];
    $mail->SMTPAuth = true;
    $mail->Username = (string) $settings['smtp_username'];
    $mail->Password = (string) $settings['smtp_password'];
    $mail->Port = (int) $settings['smtp_port'];
    $mail->SMTPSecure = (string) $settings['smtp_encryption'] === 'ssl'
        ? PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_SMTPS
        : PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
    $mail->CharSet = 'UTF-8';
    $mail->setFrom((string) $settings['from_email'], (string) $settings['from_name']);
    $mail->addAddress((string) $settings['to_email']);
    $mail->addReplyTo($email, $name);
    $mail->isHTML(false);
    $mail->Subject = '[EXALINK] ' . $areas[$area];
    $mail->Body = implode("\n", [
        'EXALINK – Contact website',
        'Name: ' . $name,
        'Company: ' . $company,
        'Email: ' . $email,
        'Phone: ' . $phone,
        'Project area: ' . $areas[$area],
        '',
        $message,
    ]);
    $mail->send();
} catch (Throwable $error) {
    error_log('EXALINK contact: mail dispatch failed');
    response(503, ['ok' => false, 'error' => 'mail_unavailable']);
}
$_SESSION['last_contact_sent'] = $now;
unset($_SESSION['contact_token'], $_SESSION['contact_started']);
response(200, ['ok' => true, 'message' => 'sent']);
