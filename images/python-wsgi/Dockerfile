FROM alpine:3.18

MAINTAINER Rich Braun "richb@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
ARG TAG
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-3.0 \
    org.label-schema.name=python-wsgi \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/python-wsgi
ENV PYTHONPATH=
ARG PIP_VERSION=23.2.1
ARG PYTHON_VERSION=3.11.5-r0
ARG PYCRYPTOGRAPHY_VERSION=41.0.3-r0
ARG PYPILLOW_VERSION=9.5.0-r1
ARG UWSGI_VERSION=2.0.22-r0

COPY Pipfile* uwsgi.ini /usr/src/

RUN echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' \
      >>/etc/apk/repositories && \
    apk add --virtual .fetch-deps gcc git jpeg-dev linux-headers make \
      musl-dev libwebp-dev openssl-dev pcre-dev python3-dev zlib-dev && \
    apk add --update --no-cache geos jpeg libjpeg-turbo libwebp \
      proj py3-authlib py3-boto3 py3-botocore py3-cachetools \
      py3-cffi py3-cryptography@edge==$PYCRYPTOGRAPHY_VERSION py3-ldap3 py3-pip \
      py3-pycryptodomex py3-greenlet py3-itsdangerous py3-jinja2 \
      py3-passlib py3-pillow=$PYPILLOW_VERSION py3-requests py3-setuptools \
      py3-virtualenv py3-werkzeug python3==$PYTHON_VERSION \
      uwsgi@edge==$UWSGI_VERSION uwsgi-python3@edge zlib && \
    pip install --upgrade pipenv pip==$PIP_VERSION && \
    cd /usr/src && pipenv install --system --deploy && pip freeze && \
    apk del .fetch-deps && rm -r /var/cache/apk/* /root/.cache

CMD ["uwsgi", "--ini", "/usr/src/uwsgi.ini"]
