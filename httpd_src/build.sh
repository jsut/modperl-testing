#!/bin/bash

cd $1;

./configure \
  --prefix=$2 \
  --with-included-apr \
  --enable-deflate=static \
  --enable-proxy=static \
  --enable-auth_digest=static \
  --enable-include=static \
  --with-mpm=prefork && make && make install
# includes proxy auth_digest deflate
