#!/usr/bin/env sh

set -euo pipefail

which envsubst cat haproxy dig sort cksum sleep 1>/dev/null

[ -n "$BACKEND_SERVICE" ]
[ -n "$BACKEND_PORT" ]

haproxy_config() {
    echo -n "haproxy_config()"
    echo ": $@"
    envsubst </haproxy-fu.Haproxy.envsubst >/haproxy-fu.Haproxy.cfg
    for IPV4 in "$@"; do
        echo "    server $BACKEND_SERVICE-$IPV4 $IPV4:$BACKEND_PORT" >>/haproxy-fu.Haproxy.cfg
    done
}

haproxy_reload() {
    echo -n "haproxy_reload()"
    echo ""
    if [ -f /haproxy-fu.Haproxy.pid ] && [ -f /proc/`cat /haproxy-fu.Haproxy.pid`/exe ]; then
        haproxy -f /haproxy-fu.Haproxy.cfg \
                -p /haproxy-fu.Haproxy.pid \
                -st "`cat /haproxy-fu.Haproxy.pid`"
    else
        haproxy -f /haproxy-fu.Haproxy.cfg \
                -p /haproxy-fu.Haproxy.pid
    fi
}

PREV_CKSUM=""
while :; do
    if ! NEXT="`dig $BACKEND_SERVICE A +short | sort`"; then
        exit 1
    else
        NEXT_CKSUM="`echo "$NEXT" | cksum`"
        if [ "$PREV_CKSUM" != "$NEXT_CKSUM" ]; then
            haproxy_config $NEXT
            haproxy_reload
            PREV_CKSUM="$NEXT_CKSUM"
        fi
        sleep 8
    fi
done

# vim:ts=4:sw=4:et:
