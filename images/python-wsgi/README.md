## python-wsgi
[![](https://images.microbadger.com/badges/version/instantlinux/python-wsgi.svg)](https://microbadger.com/images/instantlinux/python-wsgi "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/python-wsgi.svg)](https://microbadger.com/images/instantlinux/python-wsgi "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/python-wsgi.svg)](https://microbadger.com/images/instantlinux/python-wsgi "Commit badge")

A python-3.7 image for running applications under alpine and UWSGI. See the requirements.txt file for the list of pypi packages included. They are built using _pip install_. I have found that the rapid succession of python 3.6 -> 3.7 -> 3.8 runtime environments in 2019/20 made shared-library installation too fragile using the Alpine py3-xxx package repos.

### Usage
Use this as a FROM in your application Dockerifle, such as:
```
FROM instantlinux/python-builder:latest

WORKDIR /opt/app
COPY requirements.txt uwsgi.ini /usr/src/
RUN pip3 install -r /usr/src/requirements.txt
    mkdir /var/opt/app && chown uwsgi /var/opt/app

COPY app/ /opt/app
RUN chmod -R g-w,o-w /opt/app

EXPOSE 8080
```

If you use this image, do not try to add alpine system packages (e.g. apk add py3-xxx) to your image. Doing that will trigger installation of certain files from the alpine 3.8 distribution, leading to shared-library filename conflicts in such packages as Pillow and pycryptodome.

[![](https://images.microbadger.com/badges/license/instantlinux/python-wsgi.svg)](https://microbadger.com/images/instantlinux/python-wsgi "License badge")
