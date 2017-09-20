FROM alpine:3.6

WORKDIR /root
RUN apk --no-cache -q add mysql-client bash
COPY docker_files/mysqldump /usr/local/bin/mysqldump
COPY docker_files/docker_entrypoint.sh /docker_entrypoint.sh

VOLUME /dump
ENTRYPOINT ["/docker_entrypoint.sh"]
