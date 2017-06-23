#! /bin/sh

if ! grep -q jsmith /etc/passwd; then
  adduser -u 401 -G users -D -s /bin/sh -g "Joe Smith" jsmith
  adduser -u 402 -G users -D -s /bin/sh -g "Sally Jones" sjones
fi
