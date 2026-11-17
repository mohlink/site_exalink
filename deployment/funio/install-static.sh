#!/usr/bin/env bash
# EXALINK — installation de préproduction Funio (site statique seulement).
# Ne modifie ni public_html à sa racine, ni WordPress, ni les sites clients.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DEST="${HOME}/public_html/exalink"

if [[ ! -d "${HOME}/public_html" ]]; then
  echo "ERREUR : public_html absent. Aucune modification effectuée." >&2
  exit 1
fi
if [[ -L "$DEST" ]]; then
  echo "ERREUR : le répertoire cible est un lien symbolique. Arrêt." >&2
  exit 1
fi
if [[ -e "$DEST" && ! -d "$DEST" ]]; then
  echo "ERREUR : la cible n'est pas un répertoire. Arrêt." >&2
  exit 1
fi
if [[ -d "$DEST" && -n "$(find "$DEST" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  echo "ERREUR : $DEST n'est pas vide. Arrêt pour éviter un écrasement." >&2
  exit 1
fi

files=(
  index.html
  about.html
  contact.html
  corporate.css
  corporate.js
  contact-delivery.js
  enhancements.css
  motion.js
  slider.css
  slider.js
  services/it-networking.html
  services/telecommunications.html
  services/smart-systems.html
  services/service.css
  services/service.js
  assets/industrial-telecom.svg
  assets/connected-systems.svg
)
for f in "${files[@]}"; do
  if [[ ! -f "$SOURCE_DIR/$f" ]]; then
    echo "ERREUR : fichier manquant dans le dépôt : $f" >&2
    exit 1
  fi
done

mkdir -p "$DEST/services" "$DEST/assets"
for f in "${files[@]}"; do
  install -m 0644 "$SOURCE_DIR/$f" "$DEST/$f"
done

# Exigence : le mode GitHub/test ne doit jamais lancer l'envoi SMTP.
if ! grep -q 'data-contact-mode="draft"' "$DEST/contact.html"; then
  echo "ATTENTION : le formulaire n'est pas explicitement en mode brouillon." >&2
  exit 1
fi

echo "Site statique installé dans : $DEST"
echo "Fichiers copiés : ${#files[@]}"
echo "Aucun fichier WordPress ou client modifié."
echo "L'envoi automatique de courriels n'est PAS activé."
echo "Ce dossier n'a pas encore d'adresse de prévisualisation configurée."
