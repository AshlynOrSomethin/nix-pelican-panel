#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source ./update.sh

curl() {
    case "${*: -1}" in
        *"repos/pelican/failing/"*)
            return 22
            ;;
        *"page=1")
            printf '%s\n' "${RELEASES_PAGE_1:?}"
            ;;
        *"page=2")
            printf '%s\n' "${RELEASES_PAGE_2:?}"
            ;;
        *)
            echo "Unexpected release page" >&2
            return 1
            ;;
    esac
}

RELEASES_PAGE_1='[
  {"tag_name":"v1.0.0","draft":false,"prerelease":false,"published_at":"2026-01-01T00:00:00Z"},
  {"tag_name":"v1.1.0-rc.1","draft":false,"prerelease":true,"published_at":"2026-02-01T00:00:00Z"},
  {"tag_name":"v2.0.0","draft":true,"prerelease":false,"published_at":"2026-03-01T00:00:00Z"}
]'
[[ $(get_latest_version wings) == "1.1.0-rc.1" ]]

RELEASES_PAGE_1=$(jq -nc '[range(100) | {tag_name:"v1.0.0",draft:false,published_at:"2026-01-01T00:00:00Z"}]')
RELEASES_PAGE_2='[{"tag_name":"v1.1.0","draft":false,"published_at":"2026-02-01T00:00:00Z"}]'
[[ $(get_latest_version panel) == "1.1.0" ]]

RELEASES_PAGE_1='[{"tag_name":"v1.0.0","draft":true,"published_at":null}]'
if get_latest_version wings >/dev/null 2>&1; then
    echo "Expected no published releases to fail" >&2
    exit 1
fi

RELEASES_PAGE_1='[{"tag_name":"invalid tag","draft":false,"published_at":"2026-01-01T00:00:00Z"}]'
if get_latest_version wings >/dev/null 2>&1; then
    echo "Expected an invalid tag to fail" >&2
    exit 1
fi

if get_latest_version failing >/dev/null 2>&1; then
    echo "Expected a failed API request to fail" >&2
    exit 1
fi

echo "Release selection tests passed"
