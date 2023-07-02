FROM alpine:3.15

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
ARG PIP_VERSION=20.2.3
ARG PYTHON_VERSION=3.9.7-r4
ARG PYCRYPTOGRAPHY_VERSION=3.3.2-r3
ARG PYPILLOW_VERSION=8.4.0-r3
ARG UWSGI_VERSION=2.0.19.1-r2

COPY Pipfile* uwsgi.ini /usr/src/
RUN apk add --virtual .fetch-deps gcc git jpeg-dev linux-headers make \
      musl-dev libwebp-dev openssl-dev pcre-dev python3-dev zlib-dev && \
    apk add --update --no-cache geos jpeg libjpeg-turbo libwebp \
      proj py3-authlib py3-boto3 py3-botocore py3-cachetools \
      py3-cffi py3-cryptography==$PYCRYPTOGRAPHY_VERSION py3-pip \
      py3-pycryptodomex py3-flask py3-flask-babel py3-greenlet py3-itsdangerous \
      py3-passlib py3-pillow=$PYPILLOW_VERSION py3-requests py3-setuptools \
      py3-virtualenv python3==$PYTHON_VERSION uwsgi==$UWSGI_VERSION \
      uwsgi-python3 zlib && \
    pip install --upgrade pipenv pip==$PIP_VERSION && \
    cd /usr/src && pipenv install --system --deploy && pip freeze && \
    apk del .fetch-deps && rm -r /var/cache/apk/* /root/.cache

CMD ["uwsgi", "--ini", "/usr/src/uwsgi.ini"]
