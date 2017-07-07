FROM node
MAINTAINER qianlong <qianlong_cw@163.com>

RUN mkdir -p /app
WORKDIR /app

RUN npm install -g grunt

COPY package.json /app/package.json
RUN npm install

COPY . /app

EXPOSE 9100

CMD grunt server