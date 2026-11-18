#!/usr/bin/env bash
# EXALINK / Funio — safe, explicit production static-file deployment.
# Default: read-only --check. Only --apply changes the managed files.
# PHP/API and SMTP secrets are NEVER deployed by this script.
set -euo pipefail

MODE="${1:---check}"
case "$MODE" in --check|--apply) ;; *) echo "Usage: bash $0 [--check|--apply]" >&2; exit 2;; esac

SRC="/home/exalink/site_exalink_source"
DEST="/home/exalink/public_html/exalink"
PRIVATE="/home/exalink/exalink_private/contact"
RUNTIME="$PRIVATE/runtime"

fail(){ echo "ERREUR: $*" >&2; exit 1; }
[[ "$(id -un)" == "exalink" ]] || fail "Exécuter avec le compte exalink."
[[ -d "$SRC/.git" && -d "$DEST" && ! -L "$DEST" ]] || fail "Sources ou destination incorrectes."
[[ -d "$PRIVATE" && ! -L "$PRIVATE" && -r "$PRIVATE/config.php" ]] || fail "Dossier privé absent."
[[ -d "$RUNTIME" && -f "$RUNTIME/contact.php" && -f "$RUNTIME/csrf.php" ]] || fail "Isoler le PHP avec freeze-contact-runtime.sh AVANT de déployer."
[[ -f "$DEST/contact.html" && ! -L "$DEST/contact.html" && -f "$DEST/api/contact.php" ]] || fail "Fichiers de production manquants."
grep -Fq 'data-contact-mode="smtp"' "$DEST/contact.html" || fail "La version de production n'est pas en mode SMTP."
grep -Fq "$RUNTIME/contact.php" "$DEST/api/contact.php" || fail "API PHP encore liée au dépôt GitHub."
grep -Fq "$RUNTIME/csrf.php" "$DEST/api/csrf.php" || fail "API CSRF encore liée au dépôt GitHub."
grep -Fq 'data-contact-mode="draft"' "$SRC/contact.html" || fail "Le modèle GitHub doit rester draft."
grep -Fq 'rateLimited:"Trop de demandes' "$SRC/contact-delivery.js" || fail "Script contact inattendu."
grep -Fq 'location.protocol==="https:" && /^(www' "$SRC/contact-delivery.js" || fail "Origine SMTP non restreinte."
php -l "$RUNTIME/contact.php" >/dev/null
php -l "$RUNTIME/csrf.php" >/dev/null
php -l "$RUNTIME/rate-limit.php" >/dev/null

# Strict allowlist: never touch /api, .htaccess, config.php, other domains or hidden files.
files=(
  index.html about.html contact.html corporate.css corporate.js contact-delivery.js
  enhancements.css motion.js slider.css slider.js
  services/it-networking.html services/telecommunications.html
  services/smart-systems.html services/service.css services/service.js
  assets/industrial-telecom.svg assets/connected-systems.svg
)
TMP="$(mktemp -d "$PRIVATE/.safe-site-XXXXXXXX")"
cleanup(){ [[ -d "$TMP" ]] && rm -rf -- "$TMP"; }
trap cleanup EXIT

for file in "${files[@]}"; do
  [[ -f "$SRC/$file" && ! -L "$SRC/$file" ]] || fail "Source absente ou lien symbolique: $file"
  [[ ! -L "$DEST/$file" ]] || fail "Lien symbolique dans destination: $file"
  [[ -f "$DEST/$file" || ! -e "$DEST/$file" ]] || fail "Destination inattendue: $file"
  mkdir -p "$TMP/$(dirname "$file")"
  if [[ "$file" == "contact.html" ]]; then
    # Turn on SMTP only at publish time, keeping GitHub Pages draft-only.
    sed -e 's/data-contact-mode="draft"/data-contact-mode="smtp"/' \
        -e 's/contact-delivery.js?v=2/contact-delivery.js?v=3/' \
        "$SRC/$file" > "$TMP/$file"
  else
    cp "$SRC/$file" "$TMP/$file"
  fi
done
grep -Fq 'data-contact-mode="smtp"' "$TMP/contact.html" || fail "SMTP non activé dans la prévisualisation."
grep -Fq 'contact-delivery.js?v=3' "$TMP/contact.html" || fail "Version JS de production inattendue."
if command -v node >/dev/null 2>&1; then
  for file in corporate.js contact-delivery.js motion.js slider.js services/service.js; do
    node --check "$TMP/$file" || fail "JavaScript invalide: $file"
  done
fi
echo "EXALINK / Funio — fichiers autorisés uniquement:"
changes=0
for file in "${files[@]}"; do
  if [[ ! -f "$DEST/$file" ]] || ! cmp -s "$TMP/$file" "$DEST/$file"; then
    echo "  DIFFÉRENT: $file"
    changes=$((changes+1))
  fi
done
echo "Fichiers différents: $changes sur ${#files[@]}"
echo "Intacts: /api, config.php, .htaccess, tout autre site/domaine."
if [[ "$MODE" == "--check" ]]; then
  echo "VÉRIFICATION SEULEMENT : aucune modification de production."
  exit 0
fi
if [[ "$changes" -eq 0 ]]; then
  echo "Aucune modification nécessaire."
  exit 0
fi
umask 077
BACKUP="$(mktemp -d "$PRIVATE/site_backup_XXXXXXXX")"
manifest="$BACKUP/restore-list.txt"
for file in "${files[@]}"; do
  if [[ -f "$DEST/$file" ]]; then
    mkdir -p "$BACKUP/$(dirname "$file")"
    cp -p "$DEST/$file" "$BACKUP/$file"
    printf '%s\n' "$file" >> "$manifest"
  fi
done
chmod 0700 "$BACKUP"

# Each file is written to same-dir temporary path and then renamed.
for file in "${files[@]}"; do
  if [[ ! -f "$DEST/$file" ]] || ! cmp -s "$TMP/$file" "$DEST/$file"; then
    mkdir -p "$DEST/$(dirname "$file")"
    new="$DEST/$file.exalink-new"
    [[ ! -e "$new" && ! -L "$new" ]] || fail "Fichier temporaire existant: $new"
    install -m 0644 "$TMP/$file" "$new"
    mv -f -- "$new" "$DEST/$file"
  fi
done
grep -Fq 'data-contact-mode="smtp"' "$DEST/contact.html" || fail "Déploiement incomplet: vérifier la sauvegarde $BACKUP"
echo "SITE MIS À JOUR. Sauvegarde privée: $BACKUP"
echo "Vérifier le site public. Les fichiers PHP et SMTP sont inchangés."
