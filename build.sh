#!/usr/bin/env bash
# Project-wide codegen pipeline.
#
# Why the post-processing step at the bottom?
# easy_localization's generator emits each JSON value into a Dart double-quoted
# string literal as-is. Any literal `$` in a translation (e.g. "$1,000 USD")
# would otherwise be parsed by Dart as the start of a string interpolation and
# break the build. We escape `$` → `\$` after generation so translations can
# include `$` freely.
set -euo pipefail

dart run build_runner build --delete-conflicting-outputs
dart run easy_localization:generate --source-dir assets/translations
dart run easy_localization:generate -S assets/translations -f keys -o translations.g.dart

# Escape any literal `$` to `\$` in the generated codegen loader so translations
# containing `$` (currency formatting, etc.) compile under Dart's string-literal
# interpolation rules.
GEN=lib/generated/codegen_loader.g.dart
if [ -f "$GEN" ]; then
  perl -pi -e 's/(?<!\\)\$/\\\$/g' "$GEN"
fi