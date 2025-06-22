FROM alpine:latest AS base

# arm64-specific stage
FROM base AS build-arm64
ARG ARCH=aarch64

# amd64-specific stage
FROM base AS build-amd64
ARG ARCH=x86_64

FROM build-${TARGETARCH} AS build

ENV PHP_VERSION="82"
ARG S6_OVERLAY_VERSION="3.2.1.0"
ARG INCLUDES_BASEURL="https://raw.githubusercontent.com/braingremlin85/docker-dokuwiki/master/includes/"



RUN apk update && apk upgrade

RUN apk add --no-cache shadow bash curl tzdata

RUN apk add --no-cache apache2-proxy php${PHP_VERSION}-fpm 

RUN apk --no-cache add freetype-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	icu-dev \
	libbz2 \
	openssl-dev \
	php${PHP_VERSION}-common \
	php${PHP_VERSION}-session \
	php${PHP_VERSION}-gd \
	php${PHP_VERSION}-intl \
	php${PHP_VERSION}-bz2 \
	php${PHP_VERSION}-mbstring \
	php${PHP_VERSION}-openssl
	
# create a user for running services
#RUN groupmod -g 1000 users && useradd -u 911 -U -d /config -s /bin/false abc && usermod -G users abc

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-${ARCH}.tar.xz


ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz

RUN rm -rf /tmp/*

ADD ${INCLUDES_BASEURL}init-usermap-type /etc/s6-overlay/s6-rc.d/init-usermap/type
ADD ${INCLUDES_BASEURL}init-usermap-up /etc/s6-overlay/s6-rc.d/init-usermap/up
ADD ${INCLUDES_BASEURL}init-usermap-run /etc/s6-overlay/s6-rc.d/init-usermap/run
RUN chmod +x /etc/s6-overlay/s6-rc.d/init-usermap/run

ADD ${INCLUDES_BASEURL}set-timezone-type /etc/s6-overlay/s6-rc.d/set-timezone/type
ADD ${INCLUDES_BASEURL}set-timezone-up /etc/s6-overlay/s6-rc.d/set-timezone/up
ADD ${INCLUDES_BASEURL}set-timezone-run /etc/s6-overlay/s6-rc.d/set-timezone/run
RUN chmod +x /etc/s6-overlay/s6-rc.d/set-timezone/run

ADD ${INCLUDES_BASEURL}svc-httpd-type /etc/s6-overlay/s6-rc.d/svc-httpd/type
ADD ${INCLUDES_BASEURL}svc-httpd-run /etc/s6-overlay/s6-rc.d/svc-httpd/run
RUN chmod +x /etc/s6-overlay/s6-rc.d/svc-httpd/run

ADD ${INCLUDES_BASEURL}svc-php-fpm-type /etc/s6-overlay/s6-rc.d/svc-php-fpm/type
ADD ${INCLUDES_BASEURL}svc-php-fpm-run /etc/s6-overlay/s6-rc.d/svc-php-fpm/run
RUN chmod +x /etc/s6-overlay/s6-rc.d/svc-php-fpm/run


RUN	mkdir /etc/s6-overlay/s6-rc.d/init-usermap/dependencies.d && touch /etc/s6-overlay/s6-rc.d/init-usermap/dependencies.d/base && \
	mkdir /etc/s6-overlay/s6-rc.d/set-timezone/dependencies.d && touch /etc/s6-overlay/s6-rc.d/set-timezone/dependencies.d/base && \
	mkdir /etc/s6-overlay/s6-rc.d/svc-httpd/dependencies.d && touch /etc/s6-overlay/s6-rc.d/svc-httpd/dependencies.d/init-usermap && \
	mkdir /etc/s6-overlay/s6-rc.d/svc-php-fpm/dependencies.d && touch /etc/s6-overlay/s6-rc.d/svc-php-fpm/dependencies.d/svc-httpd

# register S6 services tu run
RUN	touch /etc/s6-overlay/s6-rc.d/user/contents.d/init-usermap && \	
	touch /etc/s6-overlay/s6-rc.d/user/contents.d/set-timezone && \	
	touch /etc/s6-overlay/s6-rc.d/user/contents.d/svc-httpd && \
	touch /etc/s6-overlay/s6-rc.d/user/contents.d/svc-php-fpm
	
ADD ${INCLUDES_BASEURL}httpd.conf /etc/apache2/httpd.conf

ADD ${INCLUDES_BASEURL}www.conf /etc/php${PHP_VERSION}/php-fpm.d/www.conf

ADD ${INCLUDES_BASEURL}php.ini /usr/local/etc/php/php.ini

ADD ${INCLUDES_BASEURL}dokuwiki_update.sh /usr/local/bin/dokuwiki_update.sh
RUN chmod +x /usr/local/bin/dokuwiki_update.sh

ENTRYPOINT ["/init"]

EXPOSE 80