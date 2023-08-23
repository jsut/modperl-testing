#!/bin/bash

cd $1

sh Configure \
    -des \
    -A ccflags=-fPIC \
    -Duseithreads \
    -Dusedevel \
    -Dprefix=$2 && make && make install

# HTML::HeadParser LWP::UserAgent CGI BSD::Resource Chatbot::Eliza
