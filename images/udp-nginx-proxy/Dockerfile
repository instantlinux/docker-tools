FROM nginx:1.27.4-alpine
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=udp-nginx-proxy \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV BACKENDS=self \
    INTERFACE=eth0 \    
    IP_LISTEN= \
    PORT_BACKEND=53 \
    PORT_LISTEN=53

RUN apk --update --no-cache upgrade && \
    rm /etc/nginx/conf.d/default.conf

EXPOSE 53
VOLUME /usr/local/lib
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
