#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.29.3"
FLUTTER_DIR="${HOME}/flutter"

if ! command -v flutter >/dev/null 2>&1; then
  if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
    curl --fail --location --retry 3 \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      | tar -xJ -C "${HOME}"
  fi
  export PATH="${FLUTTER_DIR}/bin:${PATH}"
fi

git config --global --add safe.directory "${FLUTTER_DIR}"
flutter config --enable-web
flutter pub get
flutter build web --release --base-href /