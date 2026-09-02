#!/usr/bin/env bash
# Idempotent Cloud Agent setup for the Qualtive Flutter client.
# Installs the Flutter SDK (stable channel, matching CI) and refreshes
# dependencies for both the plugin package and the demo app.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_DIR="${FLUTTER_HOME:-$HOME/flutter}"

# 1. Install the Flutter SDK once (stable channel, same as .github/workflows/ci.yml).
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Installing Flutter stable into $FLUTTER_DIR ..."
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# Make flutter/dart resolvable from every shell (agent tool shells and terminals).
if ! grep -qs 'flutter/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo "export PATH=\"$FLUTTER_DIR/bin:\$PATH\"" >> "$HOME/.bashrc"
fi
if command -v sudo >/dev/null 2>&1; then
  sudo ln -sf "$FLUTTER_DIR/bin/flutter" /usr/local/bin/flutter || true
  sudo ln -sf "$FLUTTER_DIR/bin/dart" /usr/local/bin/dart || true
fi

# 2. Configure Flutter for non-interactive CI-style use and web (used by the demo).
flutter config --no-analytics >/dev/null 2>&1 || true
flutter config --enable-web >/dev/null 2>&1 || true

# Warm the tool + engine artifacts so later boots don't re-download them.
flutter --version
flutter precache --web --universal

# 3. Fetch the Swift native submodule (matches CI `submodules: true`).
git -C "$REPO_ROOT" submodule update --init --recursive || true

# 4. Resolve Dart/Flutter dependencies for both packages.
(cd "$REPO_ROOT/qualtive" && flutter pub get)
(cd "$REPO_ROOT/demo" && flutter pub get)

echo "Environment setup complete."
