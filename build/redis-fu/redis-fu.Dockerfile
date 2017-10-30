FROM redis:4-alpine

RUN apk add --no-cache --virtual .envsubst gettext \
 && /bin/cp `which envsubst` /usr/local/bin \
 && apk del --no-cache .envsubst \
 && apk add --no-cache libintl

COPY redis-fu.*.envsubst redis-fu.*.sh /

ARG SENTINEL_PORT
EXPOSE $SENTINEL_PORT

WORKDIR /

ENTRYPOINT ["/redis-fu.Entrypoint.sh"]
CMD ["/redis-fu.Command.sh"]

# vim:ts=4:sw=4:et:syn=dockerfile:
