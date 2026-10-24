#!/bin/bash

cd $1

make distclean

sh Configure \
    -des \
    -A ccflags=-fPIC \
    -Duseithreads \
    -Dusedevel \
    -Dprefix=$2 && make && make install

# HTML::HeadParser LWP::UserAgent CGI BSD::Resource Chatbot::Eliza
