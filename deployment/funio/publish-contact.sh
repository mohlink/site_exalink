#!/usr/bin/env bash
# EXALINK: publish tested PHP contact form on Funio and retire staging endpoint.
# Run manually AFTER successful browser/staging SMTP tests.
set -euo pipefail
SOURCE="/home/exalink/site_exalink_source"
DEST="/home/exalink/public_html/exalink"
PRIVATE="/home/exalink/exalink_private/contact"
CONFIG="$PRIVATE/config.php"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP="$PRIVATE/production_backup_$STAMP"

[[ -d "$DEST" && ! -L "$DEST" && -f "$DEST/contact.html" ]] || { echo "ERROR: invalid destination"; exit 1; }
[[ -r "$CONFIG" && -f "$PRIVATE/vendor/autoload.php" ]] || { echo "ERROR: private mail configuration/vendor absent"; exit 1; }
[[ -f "$DEST/api/contact.php" && -f "$DEST/api/csrf.php" && -f "$DEST/contact-test.php" ]] || { echo "ERROR: staging not installed"; exit 1; }
[[ ! -L "$DEST/api" && ! -L "$DEST/contact.html" ]] || { echo "ERROR: unexpected symlink"; exit 1; }
grep -q 'data-contact-mode="draft"' "$DEST/contact.html" || { echo "ERROR: main form already changed, abort"; exit 1; }
grep -q 'data-contact-mode="draft"' "$SOURCE/contact.html" || { echo "ERROR: GitHub template must remain draft"; exit 1; }
grep -q "exalink.ca" "$SOURCE/contact-delivery.js" || { echo "ERROR: delivery adapter invalid"; exit 1; }
[[ -s "$SOURCE/deployment/funio/api/rate-limit.php" ]] || { echo "ERROR: limiter missing"; exit 1; }

php -l "$SOURCE/deployment/funio/api/contact.php"
php -l "$SOURCE/deployment/funio/api/csrf.php"
php -l "$SOURCE/deployment/funio/api/rate-limit.php"
php -l "$CONFIG"
if command -v node >/dev/null 2>&1; then node --check "$SOURCE/contact-delivery.js"; fi

# Any failure prior to this point leaves production untouched.
umask 077
mkdir -m 0700 "$BACKUP"
cp -p "$DEST/contact.html" "$DEST/contact-delivery.js" "$DEST/contact-test.php" "$BACKUP/"
cp -p "$DEST/api/contact.php" "$DEST/api/csrf.php" "$BACKUP/"
chmod 0700 "$BACKUP"

# Stage new content outside the public directory; then atomically replace.
TMPDIR="$(mktemp -d "$PRIVATE/.publish_contact.XXXXXXXX")"
trap 'rm -rf "$TMPDIR"' EXIT
mkdir "$TMPDIR/api"
sed 's/data-contact-mode="draft"/data-contact-mode="smtp"/' "$SOURCE/contact.html" > "$TMPDIR/contact.html"
cp "$SOURCE/contact-delivery.js" "$TMPDIR/contact-delivery.js"

cat > "$TMPDIR/api/csrf.php" <<'PHP'
<?php
declare(strict_types=1);
$host = strtolower(rtrim((string) ($_SERVER['HTTP_HOST'] ?? ''), '.'));
if (!in_array($host, ['exalink.ca', 'www.exalink.ca'], true)) {
    http_response_code(404);
    exit;
}
require '/home/exalink/site_exalink_source/deployment/funio/api/csrf.php';
PHP

cat > "$TMPDIR/api/contact.php" <<'PHP'
<?php
declare(strict_types=1);
$host = strtolower(rtrim((string) ($_SERVER['HTTP_HOST'] ?? ''), '.'));
if (!in_array($host, ['exalink.ca', 'www.exalink.ca'], true)) {
    http_response_code(404);
    exit;
}
putenv('EXALINK_CONFIG_PATH=/home/exalink/exalink_private/contact/config.php');
require '/home/exalink/site_exalink_source/deployment/funio/api/contact.php';
PHP

php -l "$TMPDIR/contact.html" >/dev/null
php -l "$TMPDIR/api/contact.php"
php -l "$TMPDIR/api/csrf.php"
grep -q 'data-contact-mode="smtp"' "$TMPDIR/contact.html" || exit 1
grep -q 'rateLimited:"Trop de demandes' "$TMPDIR/contact-delivery.js" || exit 1

# Write wrappers before enabling the form. Site stays in draft mode until last replace.
install -m 0644 "$TMPDIR/api/csrf.php" "$DEST/api/csrf.php.new"
install -m 0644 "$TMPDIR/api/contact.php" "$DEST/api/contact.php.new"
install -m 0644 "$TMPDIR/contact-delivery.js" "$DEST/contact-delivery.js.new"
install -m 0644 "$TMPDIR/contact.html" "$DEST/contact.html.new"
mv -f "$DEST/api/csrf.php.new" "$DEST/api/csrf.php"
mv -f "$DEST/api/contact.php.new" "$DEST/api/contact.php"
mv -f "$DEST/contact-delivery.js.new" "$DEST/contact-delivery.js"
mv -f "$DEST/contact.html.new" "$DEST/contact.html"

# Remove staging page after enabling production so it cannot be used accidentally.
rm -f -- "$DEST/contact-test.php"

echo "EXALINK production contact SMTP enabled: https://exalink.ca/contact.html"
echo "Staging-only form removed. API restricted to exalink.ca and www.exalink.ca."
echo "Private rollback backup: $BACKUP"
echo "IMPORTANT: verify HTTP status, response to CSRF and actual browser mail delivery."
