#!/usr/bin/env bash
# EXALINK — refresh only the temporary staging contact form.
# Keeps /public_html/exalink/contact.html in draft mode on the main site.
set -euo pipefail
SOURCE="/home/exalink/site_exalink_source"
DEST="/home/exalink/public_html/exalink"
PRIVATE="/home/exalink/exalink_private/contact"
STAMP="$(date +%Y%m%d_%H%M%S)"

[[ -f "$DEST/contact-test.php" && -f "$DEST/api/contact.php" && -f "$DEST/api/csrf.php" ]] || { echo "ERROR: staging is not installed."; exit 1; }
[[ -f "$SOURCE/deployment/funio/api/rate-limit.php" && -f "$SOURCE/contact.html" && -f "$SOURCE/contact-delivery.js" ]] || { echo "ERROR: updated source missing."; exit 1; }
grep -q 'data-contact-mode="draft"' "$DEST/contact.html" || { echo "ERROR: main contact page is not draft-only."; exit 1; }

# Validate before copying any files to public web tree.
php -l "$SOURCE/deployment/funio/api/contact.php"
php -l "$SOURCE/deployment/funio/api/rate-limit.php"
node_cmd=""
if command -v node >/dev/null 2>&1; then
  node --check "$SOURCE/contact-delivery.js"
fi

BACKUP="$PRIVATE/staging_backup_$STAMP"
umask 077
mkdir -p "$BACKUP"
cp -p "$DEST/contact-test.php" "$DEST/contact-delivery.js" "$BACKUP/"
chmod 0700 "$BACKUP"

# The only JS change on the public site is inert until the page explicitly
# opts in to smtp mode; production contact.html stays in draft mode.
install -m 0644 "$SOURCE/contact-delivery.js" "$DEST/contact-delivery.js"

{
  cat <<'PHP'
<?php
declare(strict_types=1);
if (strtolower((string) ($_SERVER['HTTP_HOST'] ?? '')) !== 'preprod.exalink.ca') {
    http_response_code(404);
    exit;
}
header('Cache-Control: no-store, max-age=0');
?>
PHP
  sed 's/data-contact-mode="draft"/data-contact-mode="smtp"/' "$SOURCE/contact.html"
} > "$DEST/contact-test.php"

chmod 0644 "$DEST/contact-test.php"
php -l "$DEST/contact-test.php"

echo "Staging updated. Production contact.html remains draft-only."
echo "Private backup: $BACKUP"
echo "Visit https://preprod.exalink.ca/contact-test.php"
echo "IMPORTANT: remove temporary staging endpoints after validation."
