#!/usr/bin/env bash
# EXALINK — Deploy a staging-only contact form on Funio.
# Production exalink.ca/contact.html remains in draft mode.
# No SMTP secrets are copied to public_html or GitHub.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
HOME_DIR="/home/exalink"
DEST="${HOME_DIR}/public_html/exalink"
CONFIG="${HOME_DIR}/exalink_private/contact/config.php"
API_SOURCE="${SOURCE_DIR}/deployment/funio/api"

if [[ ! -d "$DEST" || -L "$DEST" || ! -f "$DEST/contact.html" ]]; then
  echo "ERROR: Funio static site is missing or its directory is a symlink." >&2
  exit 1
fi
if [[ ! -r "$CONFIG" || ! -r "${API_SOURCE}/csrf.php" || ! -r "${API_SOURCE}/contact.php" ]]; then
  echo "ERROR: private SMTP configuration or API source not found." >&2
  exit 1
fi
if ! grep -q 'data-contact-mode="draft"' "$DEST/contact.html"; then
  echo "ERROR: public contact page is not in safe draft mode." >&2
  exit 1
fi
for f in "$DEST/contact-test.php" "$DEST/api/csrf.php" "$DEST/api/contact.php"; do
  if [[ -e "$f" || -L "$f" ]]; then
    echo "ERROR: $f already exists. No files overwritten." >&2
    exit 1
  fi
done
if [[ -L "$DEST/api" ]]; then
  echo "ERROR: api/ is a symlink. Aborting." >&2
  exit 1
fi

mkdir -p "$DEST/api"
chmod 0755 "$DEST/api"
umask 022

cat > "$DEST/contact-test.php" <<'PHP'
<?php
declare(strict_types=1);
// Staging-only. Do not serve this form through the production hostname.
if (strtolower((string)($_SERVER['HTTP_HOST'] ?? '')) !== 'preprod.exalink.ca') {
    http_response_code(404);
    exit;
}
header('Cache-Control: no-store, max-age=0');
?>
PHP
sed 's/data-contact-mode="draft"/data-contact-mode="smtp"/' "$DEST/contact.html" >> "$DEST/contact-test.php"

cat > "$DEST/api/csrf.php" <<'PHP'
<?php
declare(strict_types=1);
if (strtolower((string)($_SERVER['HTTP_HOST'] ?? '')) !== 'preprod.exalink.ca') {
    http_response_code(404);
    exit;
}
require '/home/exalink/site_exalink_source/deployment/funio/api/csrf.php';
PHP

cat > "$DEST/api/contact.php" <<'PHP'
<?php
declare(strict_types=1);
if (strtolower((string)($_SERVER['HTTP_HOST'] ?? '')) !== 'preprod.exalink.ca') {
    http_response_code(404);
    exit;
}
putenv('EXALINK_CONFIG_PATH=/home/exalink/exalink_private/contact/config.php');
require '/home/exalink/site_exalink_source/deployment/funio/api/contact.php';
PHP

chmod 0644 "$DEST/contact-test.php" "$DEST/api/csrf.php" "$DEST/api/contact.php"
php -l "$DEST/contact-test.php"
php -l "$DEST/api/csrf.php"
php -l "$DEST/api/contact.php"

echo "STAGING READY: https://preprod.exalink.ca/contact-test.php"
echo "Production contact.html remains in draft mode."
echo "Production host is blocked from contact-test.php and /api/ endpoints."
echo "IMPORTANT: This prototype is for short supervised tests, not open public use."
