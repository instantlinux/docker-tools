## python-wsgi
[![](https://images.microbadger.com/badges/version/instantlinux/python-wsgi.svg)](https://microbadger.com/images/instantlinux/python-wsgi "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/python-wsgi.svg)](https://microbadger.com/images/instantlinux/python-wsgi "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/python-wsgi.svg)](https://microbadger.com/images/instantlinux/python-wsgi "Commit badge")

A python-3.7 image for running applications under alpine and UWSGI. See the requirements.txt file for the list of pypi packages included. They are built using _pip install_. The rapid succession of python 3.6 -> 3.7 -> 3.8 runtime environments in 2019/20 made shared-library installation too fragile using the Alpine py3-xxx package repos if you're trying to stay on an older version of python.

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

If you use this image, do not try to add alpine system packages (e.g. apk add py3-xxx) to your image. Doing that will trigger installation of certain files from the alpine 3.8 distribution, leading to shared-library filename conflicts in such packages as Pillow and pycryptodome. If your pypi packages need gcc and dev packages to build, look at the Dockerfile for this image to see how you can add them in your own Dockerfile without substantially increasing image size.

[![](https://images.microbadger.com/badges/license/instantlinux/python-wsgi.svg)](https://microbadger.com/images/instantlinux/python-wsgi "License badge")
