#!/usr/bin/env sh

set -euo pipefail

which mkdir envsubst getent grep hostname nohup redis-server redis-sentinel cat sleep 1>/dev/null

[ -n "$MASTER_NAME" ]
[ -n "$SERVER_PORT" ]
[ -n "$SENTINEL_PORT" ]
[ "$SERVER_PORT" != "$SENTINEL_PORT" ]
[ -n "$QUORUM" ]
[ -n "$DOWN_AFTER" ]
[ -n "$FAILOVER_TIMEOUT" ]
[ -n "$PARALLEL_SYNCS" ]
[ -n "$REDIS_0" ]

mkdir -p /redis-fu.Server /redis-fu.Sentinel

envsubst </redis-fu.Server.envsubst >/redis-fu.Server.conf
envsubst </redis-fu.Sentinel.envsubst >/redis-fu.Sentinel.conf

if ! (getent hosts $REDIS_0 | grep -q "^`hostname -i` "); then
    echo sentinel known-slave $MASTER_NAME `hostname -i` $SERVER_PORT >>/redis-fu.Sentinel.conf
fi

# TODO: use proper signal proxy

nohup redis-server /redis-fu.Server.conf & echo -n $! >/redis-fu.Server.pid
nohup redis-sentinel /redis-fu.Sentinel.conf & echo -n $! >/redis-fu.Sentinel.pid

while [ -f /proc/`cat /redis-fu.Server.pid`/exe -a -f /proc/`cat /redis-fu.Sentinel.pid`/exe ]; do
    sleep 16
done

# vim:ts=4:sw=4:et:
