#!/bin/bash
set -euxo pipefail

HELLO_SOURCE_URL="https://github.com/$GITHUB_REPOSITORY"

if [[ "$GITHUB_REF" =~ \/v([0-9]+(\.[0-9]+)+(-.+)?) ]]; then
    HELLO_VERSION="${BASH_REMATCH[1]}"
else
    echo "ERROR: Unable to extract semver version from GITHUB_REF."
    exit 1
fi

HELLO_REVISION="$GITHUB_SHA"

IMAGE="ghcr.io/$GITHUB_REPOSITORY:$HELLO_VERSION"

docker build \
    --build-arg "HELLO_SOURCE_URL=$HELLO_SOURCE_URL" \
    --build-arg "HELLO_VERSION=$HELLO_VERSION" \
    --build-arg "HELLO_REVISION=$HELLO_REVISION" \
    -t "$IMAGE" \
    .

docker push "$IMAGE"
