#!/usr/bin/env bash
docker stop redis
docker rm -v redis
docker build -t redis ./