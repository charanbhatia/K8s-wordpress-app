FROM debian:bullseye-slim

ENV OPENRESTY_VERSION=1.21.4.1

RUN apt-get update && apt-get install -y \
    build-essential \
    libpcre3-dev \
    libssl-dev \
    perl \
    make \
    wget \
    zlib1g-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN wget https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz \
    && tar -xzf openresty-${OPENRESTY_VERSION}.tar.gz \
    && cd openresty-${OPENRESTY_VERSION} \
    && ./configure --prefix=/opt/openresty \
        --with-pcre-jit \
        --with-ipv6 \
        --without-http_redis2_module \
        --with-http_iconv_module \
        --with-http_postgres_module \
        --with-http_stub_status_module \
        -j8 \
    && make -j8 \
    && make install \
    && cd /tmp \
    && rm -rf openresty-${OPENRESTY_VERSION}*

RUN ln -s /opt/openresty/nginx/sbin/nginx /usr/local/bin/nginx

RUN groupadd -r nginx && useradd -r -g nginx nginx

COPY nginx.conf /opt/openresty/nginx/conf/nginx.conf
COPY default.conf /opt/openresty/nginx/conf/conf.d/default.conf

RUN mkdir -p /opt/openresty/nginx/conf/conf.d \
    && mkdir -p /var/log/nginx \
    && mkdir -p /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && chown -R nginx:nginx /var/cache/nginx

EXPOSE 80 443

STOPSIGNAL SIGQUIT

CMD ["/opt/openresty/nginx/sbin/nginx", "-g", "daemon off;"]
