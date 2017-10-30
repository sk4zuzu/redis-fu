#!/usr/bin/env sh

export SCRIPT_NAME="$0"
export OPERATION="$1"

set -euo pipefail

which docker mkdir envsubst ls sort kubectl 1>/dev/null

case "$OPERATION" in
    create | delete | apply)
    ;;
    *)
        echo "Usage: $SCRIPT_NAME <create | delete | apply>"
        exit 1
    ;;
esac

export SERVER_PORT=6379
export SENTINEL_PORT=26379

docker build -t redis-fu \
    --build-arg SENTINEL_PORT=$SENTINEL_PORT \
    -f ../build/redis-fu/redis-fu.Dockerfile \
    ../build/redis-fu/

mkdir -p ./.yaml-cache/

for BASENAME in *.redis-fu.*.envsubst; do
    FILENAME=${BASENAME%.*}
    envsubst <./$BASENAME >./.yaml-cache/$FILENAME.yml
done

kubectl --namespace=default $OPERATION -f ./.yaml-cache/

# vim:ts=4:sw=4:et:
