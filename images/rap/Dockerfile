FROM tomcat:8
MAINTAINER Alex Qian <qianlong_cw@163.com>

ENV CATALINA_HOME /usr/local/tomcat

# Copy RAP.war to $TOMCAT_HOME/webapps
COPY RAP-0.14.16-SNAPSHOT.war $CATALINA_HOME/webapps/ROOT.war

RUN rm -rf $CATALINA_HOME/webapps/ROOT/* \
    && unzip $CATALINA_HOME/webapps/ROOT.war -d $CATALINA_HOME/webapps/ROOT

# overwrite dubbo.properties
COPY config.properties $CATALINA_HOME/webapps/ROOT/WEB-INF/classes/config.properties

VOLUME /$CATALINA_HOME/logs

EXPOSE 8080
CMD ["catalina.sh", "run"]