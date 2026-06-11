#!/bin/zsh
#
# Build l'app Flutter pour le web et copie le résultat dans
# ../9mp.org.github.io/hellochat (servi sur https://9mp.org/hellochat/)

set -e

SCRIPT_DIR="${0:A:h}"
TARGET_DIR="$SCRIPT_DIR/../9mp.org.github.io/hellochat"

if [[ ! -d "$SCRIPT_DIR/../9mp.org.github.io" ]]; then
    print -u2 "Erreur : '$SCRIPT_DIR/../9mp.org.github.io' est introuvable."
    exit 1
fi

cd "$SCRIPT_DIR"

echo "→ Build Flutter web (release)..."
flutter build web --release --base-href /hellochat/

echo "→ Copie vers $TARGET_DIR ..."
mkdir -p "$TARGET_DIR"
rsync -a --delete "$SCRIPT_DIR/build/web/" "$TARGET_DIR/"

echo "✓ Terminé. Pense à commit/push dans 9mp.org.github.io pour publier."
