FROM haproxy:1.7-alpine

RUN apk add --no-cache --virtual .envsubst gettext \
 && /bin/cp `which envsubst` /usr/local/bin \
 && apk del --no-cache .envsubst \
 && apk add --no-cache libintl

RUN apk add --no-cache bind-tools

COPY haproxy-fu.*.envsubst haproxy-fu.*.sh /

WORKDIR /

ENTRYPOINT ["/haproxy-fu.Entrypoint.sh"]
CMD ["/haproxy-fu.Command.sh"]

# vim:ts=4:sw=4:et:syn=dockerfile:
