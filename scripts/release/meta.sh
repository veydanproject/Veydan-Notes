#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Veydan Project
# SPDX-License-Identifier: LicenseRef-PolyForm-Perimeter-1.0.1
#
# What a tag asks a release workflow for (docs/ci-cd.md, "Releases";
# internal/platform-spec.md 14.1, 14.3). Two workflows run it:
#
#   - the release.yml of a product's repository on GitHub (its snapshot):
#       GITHUB_REF_TYPE=tag GITHUB_REF_NAME=v5.1.13-rc.1 GITHUB_REPOSITORY=veydanproject/Veydan-Chat
#     → kind=own: build Windows and macOS when the tag names them (every
#       platform when it names none) and put them into a DRAFT release under
#       that tag. Linux and Android are never built there (Gitea builds them,
#       on our runner), and vX.Y.Z (a release) builds nothing: Gitea promotes
#       the files of its release candidate;
#   - the release workflow of veydanproject/release on Gitea, over a
#     checkout of the monorepo at the tag:
#       RELEASE_BUILDER=gitea GITHUB_REF_TYPE=tag GITHUB_REF_NAME=chat-v5.1.13-rc.1 GITHUB_REPOSITORY=veydanproject/monorepo
#     → kind=channel: build Linux and Android when the tag asks for them,
#       wait for the draft of GitHub when it asks for Windows or macOS,
#       assemble latest.json over every platform and publish a PRERELEASE
#       under release_tag in the product's repository;
#       … GITHUB_REF_NAME=chat-v5.1.13 FROM=chat-v5.1.13-rc.1
#     → kind=release: nothing is built; the files of from_tag become the
#       release vX.Y.Z of the product's repository (build once, promote).
#
# The grammar (14.1): <product>-vX.Y.Z[-<channel>.N[-<platform>]…] in the
# monorepo, the same without the product in its repository; channel is
# alpha, beta or rc; platforms are linux, windows, macos, android, ios,
# each at most once; none means the three desktop ones plus android.
#
# By hand: GITHUB_OUTPUT=/dev/stdout prints the outputs. It reads
# products.json and the product's crate, calls nothing and writes nothing
# but the outputs.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

fail() {
  echo "::error::$*"
  exit 1
}

: "${GITHUB_OUTPUT:?GITHUB_OUTPUT must name the file of the outputs}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must name the repository of the run}"

PRODUCTS="$(jq -r '.targets | to_entries[] | select(.value.kind == "product") | .key' products.json | xargs)"
OWN_PRODUCTS="$(jq -r '[.targets | to_entries[] | select(.value.kind == "product")] | length' products.json)"
BUILDER="${RELEASE_BUILDER:-github}"
FROM="${FROM:-}"

if [ "${GITHUB_REF_TYPE:-}" != "tag" ]; then
  fail "Run a release on a tag, not on the branch ${GITHUB_REF_NAME:-}: make push <product> … starts it"
fi
TAG="${GITHUB_REF_NAME:-}"

# The tag with the product in front, as the monorepo names it.
if [ "$OWN_PRODUCTS" = "1" ] && [ "$BUILDER" = "github" ]; then
  [[ "$TAG" =~ ^v ]] || fail "$TAG: a tag of a product's repository has no product prefix (vX.Y.Z-rc.N…)"
  FULL="$PRODUCTS-$TAG"
  OWN="true"
elif [ "$BUILDER" = "gitea" ]; then
  FULL="$TAG"
  OWN="false"
else
  fail "$TAG: the monorepo builds nothing on GitHub; a channel build is started by make push <product> alpha|beta|rc and runs on Gitea and in the product's repository"
fi

CHANNEL_RE='^([a-z]+)-v([0-9]+\.[0-9]+\.[0-9]+)-(alpha|beta|rc)\.([0-9]+)((-(linux|windows|macos|android|ios))*)$'
RELEASE_RE='^([a-z]+)-v([0-9]+\.[0-9]+\.[0-9]+)$'
if [[ "$FULL" =~ $CHANNEL_RE ]]; then
  PRODUCT="${BASH_REMATCH[1]}"
  VERSION="${BASH_REMATCH[2]}"
  CHANNEL="${BASH_REMATCH[3]}"
  KIND="channel"
  PRERELEASE="true"
  SUFFIX="${BASH_REMATCH[5]}"
  if [ -z "$SUFFIX" ]; then
    PLATFORMS="linux windows macos android"
  else
    # shellcheck disable=SC2086
    PLATFORMS="$(echo ${SUFFIX//-/ })"
    seen=" "
    for p in $PLATFORMS; do
      case "$seen" in
        *" $p "*) fail "$FULL names $p twice" ;;
      esac
      seen="$seen$p "
    done
  fi
elif [[ "$FULL" =~ $RELEASE_RE ]]; then
  PRODUCT="${BASH_REMATCH[1]}"
  VERSION="${BASH_REMATCH[2]}"
  CHANNEL="stable"
  KIND="release"
  PRERELEASE="false"
  PLATFORMS=""
  if [ "$OWN" = "true" ]; then
    fail "$TAG: a release is promoted by Gitea from its release candidate (make push $PRODUCT release); the repository of a product builds channel tags alone"
  fi
  [ -n "$FROM" ] || fail "$TAG: a release names the release candidate it promotes (FROM=<product>-vX.Y.Z-rc.N)"
  [[ "$FROM" =~ ^${PRODUCT}-v${VERSION//./\\.}-rc\.[0-9]+$ ]] || fail "$TAG: FROM=$FROM is not a release candidate of $PRODUCT $VERSION with every platform (<product>-vX.Y.Z-rc.N)"
else
  fail "Tag $FULL does not match <product>-vX.Y.Z or <product>-vX.Y.Z-(alpha|beta|rc).N[-linux|-windows|-macos|-android|-ios...]"
fi
case " $PRODUCTS " in
  *" $PRODUCT "*) ;;
  *) fail "$FULL: '$PRODUCT' is not a product of products.json ($PRODUCTS)" ;;
esac

APP="$(jq -r --arg p "$PRODUCT" '.targets[$p].app' products.json)"
REPO="$(jq -r --arg p "$PRODUCT" '.targets[$p].repo' products.json)"
if [ "$OWN" = "true" ] && [ "$GITHUB_REPOSITORY" != "$REPO" ]; then
  fail "$TAG is a tag of the repository $REPO of $PRODUCT, not of $GITHUB_REPOSITORY"
fi
FILE_VERSION="$(tr -d '[:space:]' < "$APP/VERSION")"
CONF_VERSION="$(jq -r .version "$APP/tauri.conf.json")"
if [ "$VERSION" != "$FILE_VERSION" ] || [ "$VERSION" != "$CONF_VERSION" ]; then
  fail "Tag version $VERSION does not match $APP/VERSION ($FILE_VERSION) and tauri.conf.json ($CONF_VERSION)"
fi
# The updater of an installed product reads the latest.json of the product's
# own repository, whatever built it.
ENDPOINT="$(jq -r '.plugins.updater.endpoints[0]' "$APP/tauri.conf.json")"
if [ "$ENDPOINT" != "https://github.com/$REPO/releases/latest/download/latest.json" ]; then
  fail "$APP/tauri.conf.json: the updater endpoint $ENDPOINT is not the one of $REPO"
fi
PRODUCT_NAME="$(jq -r .productName "$APP/tauri.conf.json")"
# The public half of the updater key: scripts/release/assets.mjs checks that
# every signature of a build was made by its private half.
UPDATER_PUBKEY="$(jq -r '.plugins.updater.pubkey // empty' "$APP/tauri.conf.json")"
[ -n "$UPDATER_PUBKEY" ] || fail "$APP/tauri.conf.json: no plugins.updater.pubkey"
# GitHub stores a space of an asset name as a dot.
ASSET_PREFIX="${PRODUCT_NAME// /.}"
LIB_NAME="$(sed -n '/^\[lib\]/,/^\[/s/^name = "\(.*\)"/\1/p' "$APP/Cargo.toml" | head -n1)"
MESSENGER="$(jq -r --arg p "$PRODUCT" '.targets[$p].modules | index("messenger") != null' products.json)"

# Every release lives in the product's repository, under the tag without the product.
PUBLISH_REPO="$REPO"
RELEASE_TAG="${FULL#"$PRODUCT"-}"
FROM_TAG="${FROM#"$PRODUCT"-}"
RELEASE_NAME="$PRODUCT_NAME ${RELEASE_TAG}"

include='[]'
add() {
  include=$(jq -c --arg p "$1" --arg a "$2" --arg t "$3" --arg n "$4" \
    '. + [{"platform":$p,"args":$a,"target":$t,"artifact":$n}]' <<<"$include")
}
# keys: every platform of latest.json; draft_keys: those GitHub builds into
# the draft (Windows, macOS); build_desktop: whether GitHub builds anything;
# build_linux, build_android: what Gitea builds.
keys=""
draft_keys=""
BUILD_DESKTOP="false"
BUILD_LINUX="false"
BUILD_ANDROID="false"
for p in $PLATFORMS; do
  case "$p" in
    linux)
      keys="$keys linux-x86_64"
      BUILD_LINUX="true"
      ;;
    windows)
      add "windows-latest" "" "" "windows-x86_64"
      keys="$keys windows-x86_64"
      draft_keys="$draft_keys windows-x86_64"
      BUILD_DESKTOP="true"
      ;;
    macos)
      add "macos-latest" "--target aarch64-apple-darwin" "aarch64-apple-darwin" "darwin-aarch64"
      add "macos-latest" "--target x86_64-apple-darwin" "x86_64-apple-darwin" "darwin-x86_64"
      keys="$keys darwin-aarch64 darwin-x86_64"
      draft_keys="$draft_keys darwin-aarch64 darwin-x86_64"
      BUILD_DESKTOP="true"
      ;;
    android)
      BUILD_ANDROID="true"
      ;;
    ios)
      echo "::notice::Skipping ios (not in CI yet)"
      ;;
  esac
done
if [ "$KIND" = "channel" ] && [ "$BUILD_DESKTOP" != "true" ] && [ "$BUILD_LINUX" != "true" ] && [ "$BUILD_ANDROID" != "true" ]; then
  fail "No platforms to build"
fi
# In the product's repository on GitHub only Windows and macOS are built.
if [ "$OWN" = "true" ]; then
  BUILD_LINUX="false"
  BUILD_ANDROID="false"
  [ "$BUILD_DESKTOP" = "true" ] || fail "$TAG asks for neither Windows nor macOS: nothing for this repository to build (Linux and Android are built on Gitea)"
fi
# A matrix may not be empty; the job that reads it is skipped then.
if [ "$include" = "[]" ]; then
  include='[{"platform":"ubuntu-22.04","args":"","target":"","artifact":"none"}]'
fi
# shellcheck disable=SC2086
keys="$(echo $keys)"
# shellcheck disable=SC2086
draft_keys="$(echo $draft_keys)"
MATRIX=$(jq -c '{include:.}' <<<"$include")

echo "product=$PRODUCT  version=$VERSION  kind=$KIND  channel=$CHANNEL  platforms=$PLATFORMS  → $PUBLISH_REPO $RELEASE_TAG${FROM_TAG:+ from $FROM_TAG}" >&2
{
  echo "product=$PRODUCT"
  echo "version=$VERSION"
  echo "kind=$KIND"
  echo "channel=$CHANNEL"
  echo "own=$OWN"
  echo "release_tag=$RELEASE_TAG"
  echo "release_name=$RELEASE_NAME"
  echo "from_tag=$FROM_TAG"
  echo "product_repo=$PUBLISH_REPO"
  echo "product_name=$PRODUCT_NAME"
  echo "asset_prefix=$ASSET_PREFIX"
  echo "messenger=$MESSENGER"
  echo "lib_name=$LIB_NAME"
  echo "prerelease=$PRERELEASE"
  echo "matrix=$MATRIX"
  echo "updater_keys=$keys"
  echo "draft_keys=$draft_keys"
  echo "updater_pubkey=$UPDATER_PUBKEY"
  echo "build_desktop=$BUILD_DESKTOP"
  echo "build_linux=$BUILD_LINUX"
  echo "build_android=$BUILD_ANDROID"
} >> "$GITHUB_OUTPUT"
