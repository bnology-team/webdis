FROM alpine AS stage
LABEL maintainer="Nicolas Favre-Felix <n.favrefelix@gmail.com>, Evgeny Kolyakov <evgeny.k@bnology.com>"

RUN apk update && apk add wget make gcc libevent-dev msgpack-c-dev musl-dev openssl-dev bsd-compat-headers jq git
RUN git clone https://github.com/bnology-team/webdis
RUN cd webdis && make && make install && make clean && make SSL=1 && cp webdis /usr/local/bin/webdis-ssl && cd ..
RUN sed -i -e 's/"daemonize":.*true,/"daemonize": false,/g' /etc/webdis.prod.json

# main image
FROM alpine
# Required dependencies, with versions fixing known security vulnerabilities
RUN apk update && apk add libevent msgpack-c openssl \
    redis libssl3 libcrypto3 libressl-dev openssl-dev && \
    rm -f /var/cache/apk/* /usr/bin/redis-benchmark /usr/bin/redis-cli
COPY --from=stage /usr/local/bin/webdis /usr/local/bin/webdis-ssl /usr/local/bin/
COPY --from=stage /etc/webdis.prod.json /etc/webdis.prod.json
RUN echo "daemonize yes" >> /etc/redis.conf
CMD /usr/bin/redis-server /etc/redis.conf && /usr/local/bin/webdis /etc/webdis.prod.json
