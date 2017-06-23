#!/usr/bin/env bash
docker rm -f elasticsearch
docker rmi elasticsearch
if [ ! -f "elasticsearch-5.4.2.tar.gz" ]; then
 wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.4.2.tar.gz
fi
rm -rf elasticsearch-5.4.2
tar xvfz elasticsearch-5.4.2.tar.gz
docker build -t elasticsearch ./