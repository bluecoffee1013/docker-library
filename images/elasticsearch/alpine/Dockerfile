FROM openjdk:8-jre-alpine
MAINTAINER qianlong <qianlong_cw@163.com>

# ensure elasticsearch user exists
RUN addgroup -S elasticsearch && adduser -S -G elasticsearch elasticsearch

# grab su-exec for easy step-down from root
# and bash for "bin/elasticsearch" among others
RUN apk add --no-cache 'su-exec>=0.2' bash

WORKDIR /usr/share/elasticsearch
ENV PATH /usr/share/elasticsearch/bin:$PATH
ENV INSTALL_PATH /usr/share/elasticsearch

ENV ELASTICSEARCH_VERSION 5.4.2

COPY elasticsearch-5.4.2 $INSTALL_PATH
RUN set -ex; \
	\
	apk add --no-cache --virtual .fetch-deps \
		ca-certificates \
		gnupg \
		openssl \
		tar \
	; \
	apk del .fetch-deps; \
	\
	mkdir -p ./plugins; \
	for path in \
		./data \
		./logs \
		./config \
		./config/scripts \
	; do \
		mkdir -p "$path"; \
		chown -R elasticsearch:elasticsearch "$path"; \
	done; \
	\
# we shouldn't need much RAM to test --version (default is 2gb, which gets Jenkins in trouble sometimes)
	export ES_JAVA_OPTS='-Xms1024m -Xmx1024m'; \
	if [ "${ELASTICSEARCH_VERSION%%.*}" -gt 1 ]; then \
		elasticsearch --version; \
	else \
# elasticsearch 1.x doesn't support --version
# but in 5.x, "-v" is verbose (and "-V" is --version)
		elasticsearch -v; \
	fi

COPY config $INSTALL_PATH/config

VOLUME $INSTALL_PATH/data $INSTALL_PATH/logs $INSTALL_PATH/config

COPY docker-entrypoint.sh /

EXPOSE 9200 9300
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["elasticsearch"]