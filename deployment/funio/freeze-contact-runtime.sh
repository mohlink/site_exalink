#!/usr/bin/env bash
# EXALINK / Funio - freeze the live contact PHP backend outside the Git checkout.
# Default --check is read-only; --apply performs the one-time migration.
set -euo pipefail

MODE="${1:---check}"
case "$MODE" in
  --check|--apply) ;;
  *) echo "Usage: bash $0 [--check|--apply]" >&2; exit 2 ;;
esac

SOURCE="/home/exalink/site_exalink_source/deployment/funio/api"
WEB="/home/exalink/public_html/exalink"
PRIVATE="/home/exalink/exalink_private/contact"
RUNTIME="$PRIVATE/runtime"
LEGACY="/home/exalink/site_exalink_source/deployment/funio/api"

fail() { echo "ERREUR: $*" >&2; exit 1; }
[[ "$(id -un)" == "exalink" ]] || fail "Exécuter sous le compte exalink."
[[ -d "$WEB/api" && ! -L "$WEB" && ! -L "$WEB/api" ]] || fail "Dossier Web inattendu."
[[ -d "$PRIVATE" && ! -L "$PRIVATE" && -r "$PRIVATE/config.php" ]] || fail "Configuration privée indisponible."
for file in csrf.php contact.php; do
  [[ -f "$WEB/api/$file" && ! -L "$WEB/api/$file" ]] || fail "API publiée manquante: $file"
  php -l "$WEB/api/$file" >/dev/null || fail "Syntaxe API incorrecte: $file"
done
for file in csrf.php contact.php rate-limit.php; do
  [[ -f "$SOURCE/$file" && ! -L "$SOURCE/$file" ]] || fail "Source PHP manquante: $file"
  php -l "$SOURCE/$file" >/dev/null || fail "Source PHP incorrecte: $file"
done
grep -Fq "'exalink.ca'" "$WEB/api/contact.php" || fail "Protection du domaine absente de l'API contact."
grep -Fq "'exalink.ca'" "$WEB/api/csrf.php" || fail "Protection du domaine absente de l'API CSRF."

if [[ -e "$RUNTIME" || -L "$RUNTIME" ]]; then
  [[ -d "$RUNTIME" && ! -L "$RUNTIME" ]] || fail "Répertoire runtime inattendu."
  for file in csrf.php contact.php rate-limit.php; do
    [[ -f "$RUNTIME/$file" && ! -L "$RUNTIME/$file" ]] || fail "Runtime incomplet: $file"
    php -l "$RUNTIME/$file" >/dev/null || fail "Runtime invalide: $file"
  done
  grep -Fq "$RUNTIME/csrf.php" "$WEB/api/csrf.php" || fail "Runtime présent mais API CSRF non isolée. Examiner avant toute action."
  grep -Fq "$RUNTIME/contact.php" "$WEB/api/contact.php" || fail "Runtime présent mais API contact non isolée. Examiner avant toute action."
  echo "OK: API PHP déjà isolées du dépôt GitHub. Aucune modification."
  exit 0
fi

grep -Fq "$LEGACY/csrf.php" "$WEB/api/csrf.php" || fail "Le wrapper CSRF ne correspond pas à la version connue."
grep -Fq "$LEGACY/contact.php" "$WEB/api/contact.php" || fail "Le wrapper contact ne correspond pas à la version connue."
grep -Fq "EXALINK_CONFIG_PATH=$PRIVATE/config.php" "$WEB/api/contact.php" || fail "Le chemin de configuration privée est inattendu."
echo "Pré-vérification OK : le code PHP actif dépend encore du dépôt GitHub."
echo "Cible prévue : $RUNTIME (hors du dossier public)."
echo "Sauvegarde des deux wrappers avant modification; aucun mot de passe ne sera affiché."
if [[ "$MODE" == "--check" ]]; then
  echo "Mode vérification seulement : AUCUNE modification effectuée."
  exit 0
fi

umask 077
BACKUP="$(mktemp -d "$PRIVATE/backend_backup_XXXXXXXX")"
cp -p "$WEB/api/csrf.php" "$BACKUP/csrf.php"
cp -p "$WEB/api/contact.php" "$BACKUP/contact.php"

NEW_RUNTIME="$(mktemp -d "$PRIVATE/.runtime-new-XXXXXXXX")"
cleanup() { [[ -n "${NEW_RUNTIME:-}" && -d "$NEW_RUNTIME" ]] && rm -rf -- "$NEW_RUNTIME"; }
trap cleanup EXIT
for file in csrf.php contact.php rate-limit.php; do
  install -m 0644 "$SOURCE/$file" "$NEW_RUNTIME/$file"
  php -l "$NEW_RUNTIME/$file" >/dev/null
done
chmod 0700 "$NEW_RUNTIME"

# Preserve existing host guard and private-config bootstrap; change only include targets.
sed "s|$LEGACY/csrf.php|$RUNTIME/csrf.php|g" "$BACKUP/csrf.php" > "$BACKUP/new-csrf.php"
sed "s|$LEGACY/contact.php|$RUNTIME/contact.php|g" "$BACKUP/contact.php" > "$BACKUP/new-contact.php"
php -l "$BACKUP/new-csrf.php" >/dev/null
php -l "$BACKUP/new-contact.php" >/dev/null
grep -Fq "$RUNTIME/csrf.php" "$BACKUP/new-csrf.php" || fail "Changement CSRF non valide."
grep -Fq "$RUNTIME/contact.php" "$BACKUP/new-contact.php" || fail "Changement contact non valide."

# Atomic installation of the private runtime directory.
mv -- "$NEW_RUNTIME" "$RUNTIME"
NEW_RUNTIME=""
chmod 0700 "$RUNTIME"

# Atomic file replacement. Restore original wrappers on any failure.
if install -m 0644 "$BACKUP/new-csrf.php" "$WEB/api/csrf.php.exalink-new" &&
   mv -f -- "$WEB/api/csrf.php.exalink-new" "$WEB/api/csrf.php" &&
   install -m 0644 "$BACKUP/new-contact.php" "$WEB/api/contact.php.exalink-new" &&
   mv -f -- "$WEB/api/contact.php.exalink-new" "$WEB/api/contact.php" &&
   php -l "$WEB/api/csrf.php" >/dev/null &&
   php -l "$WEB/api/contact.php" >/dev/null; then
  echo "OK: le backend PHP est maintenant isolé du dépôt GitHub."
  echo "Sauvegarde privée : $BACKUP"
  echo "Le formulaire existant et le SMTP n'ont pas été modifiés."
else
  echo "ERREUR: tentative de restauration des deux wrappers..." >&2
  rm -f -- "$WEB/api/csrf.php.exalink-new" "$WEB/api/contact.php.exalink-new"
  cp -p "$BACKUP/csrf.php" "$WEB/api/csrf.php"
  cp -p "$BACKUP/contact.php" "$WEB/api/contact.php"
  echo "Wrappers originaux restaurés. Runtime privé conservé pour diagnostic." >&2
  exit 1
fi
