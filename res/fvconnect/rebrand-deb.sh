#!/bin/bash
# Turns the stock rustdesk .deb into an fvconnect .deb.
# On Linux the app name (lowercase) is also the systemd unit, the process name
# and the config dir, so the package has to be renamed consistently.
# librustdesk.so keeps its name: the Flutter runner loads it by that name.
set -euo pipefail

IN="$1"
OUT="$2"
WORK=$(mktemp -d)
PKG="$WORK/pkg"

dpkg-deb -R "$IN" "$PKG"
# regenerated at the end with the new paths
rm -f "$PKG/DEBIAN/md5sums"

mv "$PKG/usr/share/rustdesk" "$PKG/usr/share/fvconnect"
mv "$PKG/usr/share/fvconnect/rustdesk" "$PKG/usr/share/fvconnect/fvconnect"
mv "$PKG/usr/share/fvconnect/files/systemd/rustdesk.service" \
   "$PKG/usr/share/fvconnect/files/systemd/fvconnect.service"
mv "$PKG/usr/share/applications/rustdesk.desktop" "$PKG/usr/share/applications/fvconnect.desktop"
mv "$PKG/usr/share/applications/rustdesk-link.desktop" "$PKG/usr/share/applications/fvconnect-link.desktop"
find "$PKG/usr/share/icons" -name 'rustdesk.*' | while read -r f; do
  mv "$f" "$(dirname "$f")/fvconnect.${f##*.}"
done

rebrand() {
  sed -i -E \
    -e 's/(^|[^b])rustdesk/\1fvconnect/g' \
    -e 's/RustDesk/FvConnect/g' \
    -e 's/info@fvconnect\.com/suporte@fvconnect.com.br/g' \
    "$1"
}

for f in "$PKG"/DEBIAN/control "$PKG"/DEBIAN/preinst "$PKG"/DEBIAN/postinst \
         "$PKG"/DEBIAN/prerm "$PKG"/DEBIAN/postrm \
         "$PKG/usr/share/fvconnect/files/systemd/fvconnect.service" \
         "$PKG/usr/share/applications/fvconnect.desktop" \
         "$PKG/usr/share/applications/fvconnect-link.desktop"; do
  [ -f "$f" ] && rebrand "$f"
done
sed -i 's/^Description: .*/Description: FvConnect - acesso remoto para suporte tecnico (baseado no RustDesk, AGPL-3.0)/' \
  "$PKG/DEBIAN/control"
sed -i 's|^Homepage: .*|Homepage: https://github.com/luisleno/FvConnect|' "$PKG/DEBIAN/control"

if grep -rIn --exclude-dir=lib --exclude-dir=data -E '(^|[^b])rustdesk' \
     "$PKG/DEBIAN" "$PKG/usr/share/applications" "$PKG/usr/share/fvconnect/files"; then
  echo "rustdesk still referenced in the files above" >&2
  exit 1
fi

(cd "$PKG" && find . -path ./DEBIAN -prune -o -type f -print0 | xargs -0 md5sum | sed 's| \./| |' > DEBIAN/md5sums)
dpkg-deb -b "$PKG" "$OUT"
rm -rf "$WORK"
dpkg-deb -I "$OUT"
