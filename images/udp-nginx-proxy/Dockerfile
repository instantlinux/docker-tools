FROM nginx:1.13-alpine
MAINTAINER Rich Braun "docker@instantlinux.net"

ENV BACKENDS=self \
    INTERFACE=eth0 \    
    IP_LISTEN=self \
    PORT_BACKEND=53 \
    PORT_LISTEN=53

RUN rm /etc/nginx/conf.d/default.conf
EXPOSE 53
VOLUMES /usr/local/lib
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
