#!/usr/bin/env bash
if [ ! -f "RAP-0.14.16-SNAPSHOT.war" ]
then
 wget wget -q "http://rapapi.org/release/RAP-0.14.16-SNAPSHOT.war"
fi

docker stop rap
docker rm -v rap
docker rmi rap
docker build -t rap ./