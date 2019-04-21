#!/bin/bash

procs=$(cat /proc/cpuinfo |grep processor | wc -l)
if [[ "$procs" > "${WORKER_PROCESSES:-$DEFAULT_WORKER_PROCESSES}" ]]; then
	procs=${WORKER_PROCESSES:-$DEFAULT_WORKER_PROCESSES}

fi

sed -i -r "s/worker_processes\s+[0-9]+/worker_processes $procs/" /etc/nginx/nginx.conf

sed -i -r "s/worker_connections\s+[0-9]+/worker_connections ${WORKER_CONNECTIONS:-$DEFAULT_WORKER_CONNECTIONS}/" /etc/nginx/nginx.conf

sed -i -r "s/gzip\.+;/gzip ${GZIP:-$DEFAULT_GZIP};/" /etc/nginx/nginx.conf

sed -i -r "s/pagespeed\.+;/pagespeed ${PAGESPEED:-$DEFAULT_PAGESPEED};/" /etc/nginx/nginx.conf

sed -i -r "s/client_max_body_size.+;/client_max_body_size ${UPLOAD_SIZE:-$DEFAULT_UPLOAD_SIZE};/" /etc/nginx/nginx.conf

exec nginx