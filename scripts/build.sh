#!/bin/bash
#
# build.sh compiles binary for target platforms
# it is resonsible for creating distributable files that can
# be released by a human or a script
# use: ./scripts/build.sh 0.4.8

set -eu

version="$1"
basedir="$GOPATH/src/github.com/dnote/doctor"
TMP="$basedir/build"

command_exists () {
  command -v "$1" >/dev/null 2>&1;
}

if ! command_exists shasum; then
  echo "please install shasum"
  exit 1
fi
if [ $# -eq 0 ]; then
  echo "no version specified."
  exit 1
fi
if [[ $1 == v* ]]; then
  echo "do not prefix version with v"
  exit 1
fi

build() {
  # init build dir
  rm -rf "$TMP"
  mkdir "$TMP"

  # fetch tool
  go get -u github.com/karalabe/xgo

  pushd "$basedir"

  # build linux
  xgo --targets="linux/amd64"\
    -ldflags "-X main.versionTag=$version" .
  mkdir "$TMP/linux"
  mv doctor-linux-amd64 "$TMP/linux/dnote-doctor"

  # build darwin
  xgo --targets="darwin/amd64"\
    -ldflags "-X main.versionTag=$version" .
  mkdir "$TMP/darwin"
  mv doctor-darwin-10.6-amd64 "$TMP/darwin/dnote-doctor"

  # build windows
  xgo --targets="windows/amd64"\
    -ldflags "-X main.versionTag=$version" .
  mkdir "$TMP/windows"
  mv doctor-windows-4.0-amd64.exe "$TMP/windows/dnote-doctor.exe"

  popd
}

get_buildname() {
  os=$1

  echo "dnote-doctor-${version}-${os}-amd64"
}

calc_checksum() {
  os=$1

  pushd "$TMP/$os"

  buildname=$(get_buildname "$os")
  mv dnote-doctor "$buildname"
  shasum -a 256 "$buildname" >> "$TMP/dnote-doctor-${version}-checksums.txt"
  mv "$buildname" dnote-doctor

  popd
}

build_tarball() {
  os=$1
  buildname=$(get_buildname "$os")

  pushd "$TMP/$os"

  cp "$basedir/LICENSE" .
  cp "$basedir/README.md" .
  tar -zcvf "../${buildname}.tar.gz" ./*

  popd
}

build

calc_checksum darwin
calc_checksum linux

build_tarball windows
build_tarball darwin
build_tarball linux
