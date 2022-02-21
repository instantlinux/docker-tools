## python-wsgi
[![](https://img.shields.io/docker/v/instantlinux/python-wsgi?sort=date)](https://hub.docker.com/r/instantlinux/python-wsgi/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/python-wsgi?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/python-wsgi "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/python-wsgi/Dockerfile "dockerfile")

A python-3.9 image for running applications under alpine and UWSGI. See the ]Pipfile](https://github.com/instantlinux/docker-tools/blob/main/images/python-wsgi/Pipfile) for the list of pypi packages included.

### Usage
Add your app FROM this image in your application Dockerfile, such as:
```
FROM instantlinux/python-wsgi:latest

EXPOSE 8080
WORKDIR /opt/app
COPY Pipfile* uwsgi.ini /usr/src/
RUN cd /usr/src && pipenv install --system --deploy && \
    mkdir /var/opt/app && chown uwsgi /var/opt/app

COPY app/ /opt/app
RUN chmod -R g-w,o-w /opt/app
```

If your pypi packages need gcc and dev packages to build, look at the Dockerfile for this image to see how you can add them in your own Dockerfile without substantially increasing image size.

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-GPL--3.0-red.svg)](https://choosealicense.com/licenses/gpl-3.0/ "License badge")
