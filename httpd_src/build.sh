#!/bin/bash

cd $1;

make distclean;

./configure \
  --with-z=/usr/local \
  --with-pcre=/opt/homebrew/opt/pcre2 \
  --with-ssl=/opt/homebrew/opt/openssl@3 \
  --prefix=$2 \
  --with-included-apr \
  --enable-deflate=static \
  --enable-auth_digest=static \
  --enable-include=static \
  --with-mpm=$3 && make && make install
# includes proxy auth_digest deflate
