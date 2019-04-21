ARG nginx_version=1.15.12
ARG nps_version=1.13.35.2-stable

FROM nginx:$nginx_version

ARG nginx_version
ARG nps_version

RUN apt-get update -y && \
    apt-get install -y build-essential zlib1g-dev libpcre3 libpcre3-dev unzip uuid-dev wget libssl-dev

ENV NGINX_VERSION=${nginx_version}
ENV NPS_VERSION=${nps_version}
ENV BUILD_DIR=/build

RUN mkdir ${BUILD_DIR}

RUN cd ${BUILD_DIR} && \
    wget "https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}.zip" \
    --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22" && \
    unzip v${NPS_VERSION}.zip && \
    nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d) && \
    cd "$nps_dir" && \
    NPS_RELEASE_NUMBER="${NPS_VERSION}/stable/" && \
    psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz && \
    [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL) && \
    wget ${psol_url} && \
    tar -xzvf $(basename ${psol_url})

RUN cd ${BUILD_DIR} && \
    wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
    --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22" && \
    tar -xvzf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION}/ && \
    nps_dir=$(find ${BUILD_DIR} -name "*pagespeed-ngx-${NPS_VERSION}" -type d) && \
    ./configure --add-dynamic-module=${nps_dir} --with-compat \
            --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
            --modules-path=/usr/lib/nginx/modules \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --http-log-path=/var/log/nginx/access.log \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --user=nginx \
            --group=nginx \
            --with-compat \
            --with-file-aio \
            --with-threads \
            --with-http_addition_module \
            --with-http_auth_request_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_mp4_module \
            --with-http_random_index_module \
            --with-http_realip_module \
            --with-http_secure_link_module \
            --with-http_slice_module \
            --with-http_ssl_module \
            --with-http_stub_status_module \
            --with-http_sub_module \
            --with-http_v2_module \
            --with-mail \
            --with-mail_ssl_module \
            --with-stream \
            --with-stream_realip_module \
            --with-stream_ssl_module \
            --with-stream_ssl_preread_module \
            --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
            --with-ld-opt='-Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' && \
    make && \
    make install

RUN rm /etc/nginx/conf.d/*
COPY nginx.conf /etc/nginx/

ENV DEFAULT_UPLOAD_SIZE 64M
ENV DEFAULT_WORKER_PROCESSES 1
ENV DEFAULT_WORKER_CONNECTIONS 1024
ENV DEFAULT_GZIP on
ENV DEFAULT_PAGESPEED on

COPY run_nginx.sh /
RUN chmod 750 run_nginx.sh

RUN rm -rf ${BUILD_DIR}

RUN apt-get remove -y wget build-essential zlib1g-dev libpcre3-dev unzip uuid-dev && \
    apt-get autoremove -y

CMD ["/run_nginx.sh"]