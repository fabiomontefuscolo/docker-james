#!/bin/bash

if [ ! -f "/james/conf/.docker-initialized" ];
then
    cp --archive --no-clobber \
        /james/sample/conf/*  \
        /james/conf/
    touch /james/conf/.docker-initialized
fi

exec "$@"