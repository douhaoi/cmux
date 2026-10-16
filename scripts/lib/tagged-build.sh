# shellcheck shell=bash
# Shared identity helpers for isolated LocalDeck development builds.
cmux_tag_slug_raw() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

cmux_tag_slug() {
  local slug
  slug="$(cmux_tag_slug_raw "$1")"
  printf '%s' "${slug:-agent}"
}

cmux_tag_bundle_segment() {
  local segment
  segment="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/./g; s/^\.+//; s/\.+$//; s/\.+/./g')"
  printf '%s' "${segment:-agent}"
}

cmux_validate_build_tag() {
  local slug
  slug="$(cmux_tag_slug_raw "$1")"
  if [[ -z "$slug" ]]; then
    echo "error: --tag must contain at least one ASCII letter or digit" >&2
    return 1
  fi
  if [[ "$slug" == default ]]; then
    echo "error: --tag 'default' is reserved for the stable app instance" >&2
    return 1
  fi
  if (( ${#slug} > 64 )); then
    echo "error: --tag must sanitize to at most 64 characters" >&2
    return 1
  fi
}

cmux_tag_app_path() {
  local slug
  slug="$(cmux_tag_slug "$1")"
  printf '%s/Library/Developer/Xcode/DerivedData/cmux-local-%s/Build/Products/Debug/LocalDeck DEV %s.app' "$HOME" "$slug" "$slug"
}
