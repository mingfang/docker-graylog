FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN locale-gen en_US en_US.UTF-8
ENV LANG en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc

#Runit
RUN apt-get install -y runit 
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc

#Install Oracle Java 8
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

#ElasticSearch
RUN wget -O - https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.5.2.tar.gz | tar xz && \
    mv elasticsearch-* elasticsearch

#MongoDB
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 && \
    echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.0.list && \
    apt-get update
RUN apt-get install -y mongodb-org

#server
RUN wget -O - https://packages.graylog2.org/releases/graylog2-server/graylog-1.2.0.tgz | tar zx
RUN mv graylog* graylog

#web interface
RUN wget -O - https://packages.graylog2.org/releases/graylog2-web-interface/graylog-web-interface-1.2.0.tgz | tar zx
RUN mv graylog-web-interface* graylog-web-interface

RUN mkdir -p /etc/graylog/server
COPY graylog.conf /etc/graylog/server/server.conf
COPY graylog-web-interface.conf /graylog-web-interface/conf/
COPY elasticsearch.yml /elasticsearch/config/
COPY mongod.conf /etc/

#Add runit services
COPY sv /etc/service 

#create inputs
COPY syslogTCPInput514.json /
COPY gelfTCPInput12201.json /
COPY rawTCPInput5555.json /
RUN export > /etc/envvars && \
    runsv /etc/service/mongodb & \
    runsv /etc/service/elasticsearch & \
    runsv /etc/service/graylog & \
    until /usr/bin/curl http://127.0.0.1:12900/system/inputs; do echo "waiting for API server to come online..."; sleep 3; done && \
    curl -u admin:admin -X POST -H "Content-Type: application/json" -d @syslogTCPInput514.json localhost:12900/system/inputs && \
    curl -u admin:admin -X POST -H "Content-Type: application/json" -d @gelfTCPInput12201.json localhost:12900/system/inputs && \
    curl -u admin:admin -X POST -H "Content-Type: application/json" -d @rawTCPInput5555.json localhost:12900/system/inputs && \
    sv stop graylog && \
    sv stop elasticsearch && \
    sv stop mongodb 
