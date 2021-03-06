FROM python:3.9.5-alpine3.14

MAINTAINER Rich Braun "richb@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
ARG TAG
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-3.0 \
    org.label-schema.name=python-wsgi \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/python-wsgi
ENV PYTHONPATH=/usr/lib/python3.9/site-packages
ARG CFFI_VERSION=1.14.5-r1
ARG PYCRYPTOGRAPHY_VERSION=3.3.2-r1
ARG PYPILLOW_VERSION=8.2.0-r0
ARG UWSGI_VERSION=2.0.19.1-r2

COPY Pipfile* uwsgi.ini /usr/src/
RUN apk add --virtual .fetch-deps gcc git jpeg-dev libffi-dev make musl-dev \
      libwebp-dev openssl-dev pcre-dev zlib-dev && \
    apk add --update --no-cache geos jpeg libjpeg-turbo libwebp \
      proj py3-authlib py3-boto3 py3-botocore py3-cachetools \
      py3-cffi==$CFFI_VERSION \
      py3-cryptography==$PYCRYPTOGRAPHY_VERSION \
      py3-pycryptodomex py3-flask py3-flask-babel py3-greenlet py3-itsdangerous \
      py3-pillow=$PYPILLOW_VERSION py3-requests py3-setuptools \
      py3-virtualenv uwsgi==$UWSGI_VERSION \
      uwsgi-python3 zlib && \
    pip install --upgrade pipenv pip && \
    cd /usr/src && pipenv install --system --deploy && pip freeze && \
    apk del .fetch-deps && rm -r /var/cache/apk/* /root/.cache

CMD ["uwsgi", "--ini", "/usr/src/uwsgi.ini"]
