## python-wsgi
[![](https://img.shields.io/docker/v/instantlinux/python-wsgi?sort=date)](https://microbadger.com/images/instantlinux/python-wsgi "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/python-wsgi.svg)](https://microbadger.com/images/instantlinux/python-wsgi "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/master/images/python-wsgi/Dockerfile "dockerfile")

A python-3.8 image for running applications under alpine and UWSGI. See the requirements.txt file for the list of pypi packages included.

### Usage
Add your app FROM this image in your application Dockerfile, such as:
```
FROM instantlinux/python-wsgi:latest

EXPOSE 8080
WORKDIR /opt/app
COPY requirements.txt uwsgi.ini /usr/src/
RUN pip install -r /usr/src/requirements.txt
    mkdir /var/opt/app && chown uwsgi /var/opt/app

COPY app/ /opt/app
RUN chmod -R g-w,o-w /opt/app
```

If your pypi packages need gcc and dev packages to build, look at the Dockerfile for this image to see how you can add them in your own Dockerfile without substantially increasing image size.

[![](https://images.microbadger.com/badges/license/instantlinux/python-wsgi)](https://microbadger.com/images/instantlinux/python-wsgi "License badge")
