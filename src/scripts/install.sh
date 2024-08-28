#!/usr/bin/env sh
# shellcheck disable=SC3043 # while "local" isn't POSIX, it's supported in many shells. See: https://www.shellcheck.net/wiki/SC3043

fetch_latest_version() {
  local release_notes
  local release_notes_exit_code

  release_notes="$(curl --location --silent --fail --retry 3 https://cloud.google.com/sdk/docs/release-notes)"
  release_notes_exit_code="$?"

  [ "$release_notes_exit_code" -gt 0 ] && { printf '%s\n' "Failed to get release notes"; return "$release_notes_exit_code"; }

  local releases
  releases="$(printf '%s\n' "$release_notes" | grep -E '<h2 id=".*" data-text=".*">[0-9]+.[0-9]+.[0-9]+.*</h2>' | sed 's/<h2.*>\([0-9]*.[0-9]*.[0-9]*\).*<\/h2>/\1/')"

  local latest_version
  latest_version="$(printf '%s\n' "$releases" | head -n 1)"

  [ -z "$latest_version" ] && { printf '%s\n' "Couldn't find out what is the latest version available."; return 1; }
  version="$latest_version"
}

# $1: version
install() {
  local arg_version="$1"
  [ -z "$arg_version" ] && { printf '%s\n' "No version provided."; return 1; }

  local install_dir
  install_dir="$(mktemp -d)"

  # after version 370, gcloud is called "cli" rather than "sdk"
  major_version="$(echo "$1" | awk -F. '{print $1}')"
  if [ "$major_version" -gt 370 ]; then url_path_fixture="cli"
  else url_path_fixture="sdk"; fi

  download_with_retry "$install_dir/google-cloud-sdk.tar.gz" "$url_path_fixture" "$arg_version" "$install_dir" || exit 1
  if [ "$platform" = "windows" ]; then
    cp -R "$install_dir"/google-cloud-sdk/bin/* "/c/Users/circleci/AppData/Local/Microsoft/WindowsApps/"
    cp -R "$install_dir"/google-cloud-sdk/lib "/c/Users/circleci/AppData/Local/Microsoft/WindowsApps/"
    cp -R "$install_dir"/google-cloud-sdk/platform "/c/Users/circleci/AppData/Local/Microsoft/WindowsApps/"
  fi
  printf '%s\n' ". $install_dir/google-cloud-sdk/path.bash.inc" >> "$BASH_ENV"

  # If the environment is Alpine, remind the user to source $BASH_ENV in every step.
  if [ -f /etc/os-release ] && grep -q "Alpine" "/etc/os-release"; then
    printf '%s\n' "Alpine detected. Please make sure to source \$BASH_ENV in every step."
    printf '%s\n' "Otherwise gcloud won't be available."
    printf '%s\n' "You can do this by adding the following line in the beginning of your command:"
    printf '%s\n' "\". \$BASH_ENV\""

    # Alpine also needs a workaround since Google's "path.bash.inc" doesn't work.
    printf '%s\n' "export PATH=$install_dir/google-cloud-sdk/bin:$PATH" >> "$BASH_ENV"
  fi

  # shellcheck disable=SC1090
  . "$BASH_ENV"
  if ! command -v gcloud > /dev/null 2>&1; then return 1; fi
  printf '%s\n' "Google Cloud SDK version: $(gcloud --version)"
}

uninstall() {
  if [ "${platform}" != "windows" ] && ! command -v sudo > /dev/null 2>&1; then
    printf '%s\n' "sudo is required to uninstall the Google Cloud SDK."
    printf '%s\n' "Please install it and try again."
    return 1
  fi

  # Set sudo to work whether logged in as root user or non-root user.
  if [ "$(id -u)" -eq 0 ] || [ "${platform}" = "windows" ]; then sudo=""; else sudo="sudo"; fi

  local installation_directory
  installation_directory="$(gcloud info --format='value(installation.sdk_root)')"

  local config_directory
  config_directory="$(gcloud info --format='value(config.paths.global_config_dir)')"

  # shellcheck disable=SC2086 # $sudo is not a variable, it's a command.
  $sudo rm -rf "$installation_directory" || return 1

  # shellcheck disable=SC2086 # $sudo is not a variable, it's a command.
  $sudo rm -rf "$config_directory" || return 1
}

download_and_extract() {
  local output_file="$1"
  local url_path_fixture="$2"
  local version="$3"
  local install_directory="$4"

  curl --location --silent --fail --retry 3 --output "$output_file" "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-$url_path_fixture-$version-linux-x86_64.tar.gz"
  tar -xzf "$output_file" -C "$install_directory"

  return $?
}

download_with_retry() {
  local output_file="$1"
  local url_path_fixture="$2"
  local version="$3"
  local install_directory="$4"
  local download_tries=0
  local max_download_tries=3

  while [ $download_tries -lt $max_download_tries ]; do
    if download_and_extract "$output_file" "$url_path_fixture" "$version" "$install_directory"; then
      break
    else
      download_tries=$((download_tries + 1))
      printf "Download failed, retrying... (attempt: %d)\n" "$download_tries"
      rm -rf "${install_directory:?}"/*
    fi
  done

  if [ $download_tries -ge $max_download_tries ]; then
    printf "Failed to download and extract the tar file after %d attempts.\n" "$max_download_tries"
    return 1
  fi
}

# Check if curl is installed
if ! command -v curl > /dev/null 2>&1; then
  printf '%s\n' "curl is required to install the Google Cloud SDK."
  printf '%s\n' "Please install it and try again."
  exit 1
fi

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     platform=linux;;
    Darwin*)    platform=mac;;
    CYGWIN*)    platform=windows;;
    MINGW*)     platform=windows;;
    MSYS_NT*)   platform=windows;;
    *)          platform="UNKNOWN:${unameOut}"
esac

printf "Detected platform: %s (%s)\n" "${platform}" "$(python --version)"

sort_versions () {
  local installed_version="$1"
  local version="$2"

  if [ "$platform" = "windows" ]; then
    # this leans on the knowledge that node is bundled in the machine images
    printf "%s %s" "$installed_version" "$version" | xargs npx semver | head -n 1
  else
    printf '%s\n%s\n' "$installed_version" "$version" | sort -V | head -n 1
  fi
}

# Figure out what is latest version available if "latest" is passed as an argument.
version="$ORB_VAL_VERSION"
[ "$version" = "latest" ] && fetch_latest_version

if command -v gcloud > /dev/null 2>&1; then
  installed_version="$(gcloud version | head -n 1 | sed 's/Google Cloud SDK \([0-9]*.[0-9]*.[0-9]*\)/\1/')"

  if [ "$installed_version" != "$version" ]; then
    # Figure out which version is older between the installed version and the requested version.
    older_version="$(sort_versions "$installed_version" "$version")"

    # If the version requested is "latest" and the installed version is newer than the latest version available, skip installation.
    if [ "$ORB_VAL_VERSION" = "latest" ] && [ "$older_version" = "$version" ]; then
      printf '%s\n' "The version installed ($installed_version) is newer than the latest version listed in the release notes ($version)."
      printf '%s\n' "Skipping installation."
    else
      printf '%s\n' "The version installed ($installed_version) differs from the version requested ($version)."
      printf '%s\n' "Uninstalling v${installed_version}..."
      if ! uninstall; then printf '%s\n' "Failed to uninstall the current version."; exit 1; fi

      printf '%s\n' "Installing v${version}..."
      if ! install "$version"; then printf '%s\n' "Failed to install the requested version."; exit 1; fi
    fi
  else
    printf '%s\n' "The version installed ($installed_version) matches the version requested ($version)."
    printf '%s\n' "Skipping installation."
  fi
else
  printf '%s\n' "Google Cloud SDK is not installed. Installing it."
  if ! install "$version"; then printf '%s\n' "Failed to install the requested version."; exit 1; fi
fi

# Install user provided gcloud components
if [ -n "$ORB_VAL_COMPONENTS" ]; then
  set -f
  for component in $ORB_VAL_COMPONENTS; do
      set -- "$@" "$component"
  done
  set +f

  gcloud --quiet components install "$@"
fi
