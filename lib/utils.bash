#!/usr/bin/env bash

set -euo pipefail

# TODO: Ensure this is the correct GitHub homepage where releases can be downloaded for teleport-community.
GH_REPO="https://github.com/gravitational/teleport/"
TOOL_NAME="teleport-community"
# TOOL_TEST="teleport-community --help"

OS="${OS:-unknown}"
ARCH="${ARCH:-unknown}"

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if teleport-community is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "$GH_REPO" |
    grep -oE 'refs/tags/v[0-9]+.[0-9]+.[0-9]+$' |
    cut -d/ -f3- |
    sed 's/^v//' |
    sort -V
    # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
  # TODO: Adapt this. By default we simply list the tag names from GitHub releases.
  # Change this function if teleport-community has other means of determining installable versions.
  list_github_tags
}

detect_os() {
  if [ "$OS" = "unknown" ]; then
    case $(uname | tr '[:upper:]' '[:lower:]') in
    linux*)
      echo 'linux'
      ;;
    darwin*)
      fail 'darwin based os is not supported yet'
      ;;
    msys* | cygwin* | mingw* | nt | win*)
      fail 'windows based os is not supported yet'
      ;;
    *)
      # TODO Error message
      fail "Unknown operating system. Please provide the operating system version by setting \$OS."
      ;;
    esac
  else
    echo "$OS"
  fi
}

detect_arch() {
  if [ "$ARCH" = "unknown" ]; then
    case $(uname -m) in
    x86_64)
      echo "amd64"
      ;;
    i386)
      echo "386"
      ;;
    armv7l)
      echo "arm"
      ;;
    aarch64)
      echo "arm64"
      ;;
    **)
      fail "ERROR: Your system's architecture isn't officially supported or couldn't be determined. \nPlease refer to the installation guide for more information: \nhttps://goteleport.com/docs/installation/"
      ;;
    esac
  else
    echo "$ARCH"
  fi
}

download_release() {
  local version filename url
  version="$1"
  filename="$2"

  KERNEL_VERSION=$(uname -r)
  MIN_VERSION="2.6.23"
  if [ $MIN_VERSION != "$(echo -e "$MIN_VERSION\n$KERNEL_VERSION" | sort -V | head -n1)" ]; then
    echo "ERROR: Teleport requires Linux kernel version $MIN_VERSION+"
    exit 1
  fi

  os=$(detect_os)
  arch=$(detect_arch "$os")

  # AMD 32bit https://cdn.teleport.dev/teleport-v11.1.2-linux-386-bin.tar.gz
  # ARM 64bit https://cdn.teleport.dev/teleport-v11.1.2-linux-arm64-bin.tar.gz
  # AMD 64bit https://cdn.teleport.dev/teleport-v11.1.2-linux-amd64-bin.tar.gz

  url="https://cdn.teleport.dev/teleport-v${version}-${os}-${arch}-bin.tar.gz"

  echo "* Downloading $TOOL_NAME release $version..."
  curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}


install_version() {
  local install_type="$1"
  local version="$2"
  # the directory where Teleport binaries will be located
  local bindir=/usr/local/bin
  # the directory where Teleport will keep its state/data
  local vardir=/var/lib/teleport

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi

  (
    mkdir -p $vardir $bindir
    cd "$ASDF_DOWNLOAD_PATH"
    cp -f teleport tctl tsh tbot $bindir || exit 1
    echo "$TOOL_NAME $version installation was successful!"
  ) || (
    fail "An error occurred while installing $TOOL_NAME $version."
  )

  # (
  #   mkdir -p "$install_path"
  #   cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

  #   # TODO: Assert teleport-community executable exists.
  #   local tool_cmd
  #   tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
  #   test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

  #   echo "$TOOL_NAME $version installation was successful!"
  # ) || (
  #   rm -rf "$install_path"
  #   fail "An error occurred while installing $TOOL_NAME $version."
  # )
}

uninstall() {
  # the directory where Teleport binaries will be located
  local bindir=/usr/local/bin
  (
    cd $bindir
    rm teleport tctl tsh tbot || exit 1
    echo "$TOOL_NAME was uninstalled successfully!"
  ) || (
    fail "An error occurred while uninstalling $TOOL_NAME."
  )
}
