#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/gravitational/teleport/"
TOOL_NAME="teleport-community"
TOOL_TEST="tsh version"

OS="${OS:-unknown}"
ARCH="${ARCH:-unknown}"

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

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
}

list_all_versions() {
  list_github_tags
}

detect_os() {
  if [ "$OS" = "unknown" ]; then
    case $(uname | tr '[:upper:]' '[:lower:]') in
    linux*)
      echo 'linux'
      ;;
    darwin*)
      echo 'darwin'
      ;;
    msys* | cygwin* | mingw* | nt | win*)
      fail 'windows based os is not supported yet'
      ;;
    *)
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
    arm64 | aarch64)
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

  url="https://cdn.teleport.dev/teleport-v${version}-${os}-${arch}-bin.tar.gz"

  echo "* Downloading $TOOL_NAME release $version..."
  curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="$3"

  major_version=$(echo "$version" | cut -d. -f1)
  os=$(detect_os)

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi

  (
    mkdir -p "$install_path"

    cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

    mkdir -p "$install_path"/bin
    mv "$install_path"/teleport "$install_path"/bin/teleport
    mv "$install_path"/tbot "$install_path"/bin/tbot
    if [ "$os" = "darwin" ] && [ "$major_version" -gt 16 ]; then
      mv "$install_path"/tctl.app/Contents/MacOS/tctl "$install_path"/bin/tctl
      mv "$install_path"/tsh.app/Contents/MacOS/tsh "$install_path"/bin/tsh
    else
      mv "$install_path"/tctl "$install_path"/bin/tctl
      mv "$install_path"/tsh "$install_path"/bin/tsh
    fi

    local tool_cmd
    tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
    test -x "$install_path/bin/$tool_cmd" || fail "Expected $install_path/bin/$tool_cmd to be executable."

    echo "$TOOL_NAME $version installation was successful!"
  ) || (
    fail "An error occurred while installing $TOOL_NAME $version."
  )
}
