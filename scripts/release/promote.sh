#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Veydan Project
# SPDX-License-Identifier: LicenseRef-PolyForm-Perimeter-1.0.1
#
# The last job of the release workflow of Gitea (veydanproject/release):
# what GitHub built, what Gitea built and latest.json become the one
# release of the product in its repository on GitHub (docs/ci-cd.md,
# "Releases"; build once, promote many).
#
#   KIND=channel   the desktop bundles are in the DRAFT release GitHub made
#                  under RELEASE_TAG (when BUILD_DESKTOP=true): wait for it,
#                  take its files, check every signature against the public
#                  key of the product; add what ASSETS_DIR holds (the APK);
#                  publish the prerelease with latest.json
#   KIND=release   the files of the prerelease FROM_TAG (the release
#                  candidate) become the release RELEASE_TAG: downloaded,
#                  checked, published again with a latest.json that names
#                  the new tag; nothing is built
#
#   REPO, RELEASE_TAG, RELEASE_NAME, ASSET_PREFIX, VERSION, UPDATER_KEYS, GH_TOKEN
#                  as scripts/release/publish.sh reads them
#   UPDATER_PUBKEY the public key of plugins.updater.pubkey
#   BUILD_DESKTOP  channel: whether GitHub builds desktop bundles for this tag
#   ASSETS_DIR     channel: the files Gitea built (may be empty)
#   WAIT_MINUTES   how long to wait for the draft (60)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail() {
  echo "::error::$*"
  exit 1
}

: "${KIND:?}" "${REPO:?}" "${RELEASE_TAG:?}" "${RELEASE_NAME:?}" "${ASSET_PREFIX:?}" "${VERSION:?}" "${UPDATER_PUBKEY:?}"
[ -n "${GH_TOKEN:-}" ] || fail "No token to publish $RELEASE_TAG in $REPO with"
UPDATER_KEYS="${UPDATER_KEYS:-}"
ASSETS_DIR="${ASSETS_DIR:-release-assets}"
WAIT_MINUTES="${WAIT_MINUTES:-60}"
mkdir -p "$ASSETS_DIR"

# The assets of a release as `name<TAB>url`, or nothing when there is no release.
assets_of() {
  gh api "repos/$REPO/releases/tags/$1" --jq '.assets[] | "\(.name)\t\(.url)"' 2>/dev/null || true
}
# A draft is not found by its tag: it is listed.
draft_of() {
  gh api "repos/$REPO/releases?per_page=50" --jq ".[] | select(.draft == true and .tag_name == \"$1\") | .id" 2>/dev/null | head -n1
}
download_release() {
  local id="$1" dir="$2" names n url
  mkdir -p "$dir"
  names="$(gh api "repos/$REPO/releases/$id" --jq '.assets[] | "\(.name)\t\(.id)"')"
  while IFS=$'\t' read -r n aid; do
    [ -n "$n" ] || continue
    [ "$n" = "latest.json" ] && continue
    gh api -H "Accept: application/octet-stream" "repos/$REPO/releases/assets/$aid" > "$dir/$n"
  done <<<"$names"
}

case "$KIND" in
  channel)
    if [ "${BUILD_DESKTOP:-false}" = "true" ]; then
      # The draft GitHub leaves: every desktop platform's signed bundle.
      echo ">> waiting for the draft $RELEASE_TAG of $REPO (up to $WAIT_MINUTES min)"
      deadline=$(( $(date +%s) + WAIT_MINUTES * 60 ))
      while :; do
        ID="$(draft_of "$RELEASE_TAG")"
        if [ -n "$ID" ]; then
          rm -rf "$ASSETS_DIR/desktop" && download_release "$ID" "$ASSETS_DIR/desktop"
          if node "$HERE/assets.mjs" verify --dir "$ASSETS_DIR/desktop" --prefix "$ASSET_PREFIX" --version "$VERSION" --keys "$UPDATER_KEYS" --pubkey "$UPDATER_PUBKEY" 2>/dev/null; then
            break
          fi
          echo ">> the draft is there but not complete yet"
        fi
        [ "$(date +%s)" -lt "$deadline" ] || fail "$REPO: no complete draft $RELEASE_TAG within $WAIT_MINUTES minutes (did the build on GitHub fail?)"
        sleep 60
      done
      # Checked once more, loudly: a wrong signature stops the release here.
      node "$HERE/assets.mjs" verify --dir "$ASSETS_DIR/desktop" --prefix "$ASSET_PREFIX" --version "$VERSION" --keys "$UPDATER_KEYS" --pubkey "$UPDATER_PUBKEY"
      mv "$ASSETS_DIR"/desktop/* "$ASSETS_DIR"/ && rmdir "$ASSETS_DIR/desktop"
    fi
    ;;
  release)
    : "${FROM_TAG:?a release names the candidate it promotes}"
    # The candidate must be published (not a draft) and complete.
    STATE="$(gh api "repos/$REPO/releases/tags/$FROM_TAG" --jq '{draft, prerelease, id}' 2>/dev/null)" || fail "$REPO has no release $FROM_TAG"
    jq -e '.draft == false and .prerelease == true' <<<"$STATE" >/dev/null || fail "$REPO: $FROM_TAG is not a published prerelease: $STATE"
    download_release "$(jq -r .id <<<"$STATE")" "$ASSETS_DIR"
    [ -z "$UPDATER_KEYS" ] && UPDATER_KEYS="$(jq -r '.platforms | keys | join(" ")' <<<"$(gh release download "$FROM_TAG" --repo "$REPO" --pattern latest.json -O - 2>/dev/null || echo '{"platforms":{}}')")"
    node "$HERE/assets.mjs" verify --dir "$ASSETS_DIR" --prefix "$ASSET_PREFIX" --version "$VERSION" --keys "$UPDATER_KEYS" --pubkey "$UPDATER_PUBKEY"
    # The tag of the release points at the commit of the candidate: made by
    # make push <product> release before this run; nothing else may make it.
    gh api "repos/$REPO/git/ref/tags/$RELEASE_TAG" --jq .object.sha >/dev/null 2>&1 || fail "$REPO has no tag $RELEASE_TAG: make push <product> release makes it on the commit of $FROM_TAG"
    ;;
  *) fail "KIND=$KIND: channel or release" ;;
esac

# Everything together, as the one release.
ls -la "$ASSETS_DIR"
export MODE="$KIND" REPO RELEASE_TAG RELEASE_NAME ASSET_PREFIX VERSION UPDATER_KEYS ASSETS_DIR
bash "$HERE/publish.sh"

# The sums of what was published, for the record of the run.
(cd "$ASSETS_DIR" && sha256sum -- * > SHA256SUMS) && gh release upload "$RELEASE_TAG" "$ASSETS_DIR/SHA256SUMS" --repo "$REPO" --clobber
echo ">> promoted: https://github.com/$REPO/releases/tag/$RELEASE_TAG"
