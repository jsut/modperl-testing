#!/bin/bash

cd $1;

make distclean;

$2/bin/perl$3 Makefile.PL MP_APXS=$4/bin/apxs MP_NO_THREADS=1 MP_CCOPTS="-fgnu89-inline" LDFLAGS="-Wl,-undefined,dynamic_lookup" && make && make test

