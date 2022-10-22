#!/usr/bin/env sh
# shellcheck disable=SC3043 # while "local" isn't POSIX, it's support in many shells. See: https://www.shellcheck.net/wiki/SC3043

home="$(printf '%s\n' "$HOME" | sed 's/\//\\\//g')"
readonly home

base_dir="$(printf '%s\n' "$CIRCLE_WORKING_DIRECTORY" | sed "s/~/$home/")"
readonly base_dir

fetch_latest_version() {
    local release_notes
    local release_notes_exit_code
    
    release_notes="$(curl --location --silent --fail --retry 3 https://cloud.google.com/sdk/docs/release-notes)"
    release_notes_exit_code="$?"

    [ "$release_notes_exit_code" -gt 0 ] && printf '%s\n' "Failed to get release notes" && return "$release_notes_exit_code"

    local releases
    releases="$(printf '%s\n' "$release_notes" | grep -E '<h2 id=".*" data-text=".*">[0-9]+.[0-9]+.[0-9]+.*</h2>' | sed 's/<h2.*>\([0-9]*.[0-9]*.[0-9]*\).*<\/h2>/\1/')"

    local latest_version
    latest_version="$(printf '%s\n' "$releases" | head -n 1)"

    [ -z "$latest_version" ] && printf '%s\n' "Failed to resolve what is the latest version available." && return 1
    version="$latest_version"
}

# $1: version
install() {
  local arg_version="$1"
  [ -z "$arg_version" ] && printf '%s\n' "No version provided." && return 1
  cd "$base_dir" || return 1
  curl --location --silent --fail --retry 3 https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-"$arg_version"-linux-x86_64.tar.gz | tar xz
  printf '%s\n' "source $base_dir/google-cloud-sdk/path.bash.inc" >> "$BASH_ENV"
}

uninstall() {
if ! command -v sudo > /dev/null 2>&1; then
  printf '%s\n' "sudo is required to uninstall the Google Cloud SDK."
  printf '%s\n' "Please install it and try again."
  return 1
fi

# Set sudo to work whether logged in as root user or non-root user.
if [ "$(id -u)" -eq 0 ]; then sudo=""; else sudo="sudo"; fi

local installation_directory
installation_directory="$(gcloud info --format='value(installation.sdk_root)')"

local config_directory
config_directory="$(gcloud info --format='value(config.paths.global_config_dir)')"

"$sudo" rm -rf "$installation_directory" || return 1
"$sudo" rm -rf "$config_directory" || return 1
}

# Check if curl is installed
if ! command -v curl > /dev/null 2>&1; then
  printf '%s\n' "curl is required to install the Google Cloud SDK."
  printf '%s\n' "Please install it and try again."
  exit 1
fi

# Figure out what is latest version available if "latest" is passed as an argument.
version="$ORB_VAL_VERSION"
[ "$version" = "latest" ] && fetch_latest_version

if command -v gcloud > /dev/null 2>&1; then
  installed_version="$(gcloud version | head -n 1 | sed 's/Google Cloud SDK \([0-9]*.[0-9]*.[0-9]*\)/\1/')"

  if [ "$installed_version" != "$version" ]; then
    printf '%s\n' "The version installed ($installed_version) differs from the version requested ($version)."
    printf '%s\n' "Uninstalling v${installed_version}..."
    
    if ! uninstall; then
      readonly uninstall_error_code="$?"
      printf '%s\n' "Failed to uninstall the current version."
      exit "$uninstall_error_code"
    fi
    
    printf '%s\n' "Installing v${version}..."

    if ! install "$version"; then
      readonly install_error_code="$?"
      printf '%s\n' "Failed to install the requested version."
      exit "$install_error_code"
    fi
  else
    printf '%s\n' "The version installed ($installed_version) matches the version requested ($version)."
    printf '%s\n' "Skipping installation."
  fi
else
  printf '%s\n' "Google Cloud SDK is not installed. Installing it."

  if ! install "$version"; then
    readonly install_error_code="$?"
    printf '%s\n' "Failed to install the requested version."
    exit "$install_error_code"
  fi
fi