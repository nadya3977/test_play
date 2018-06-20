FROM nginx:stable-alpine

# Nginx user not supported with user namespace mapping
USER root

ENV NGINX_PORT=8080

COPY nginx/html /usr/share/nginx/html
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf.template /etc/nginx/conf.d/
RUN mkdir -p /var/cache/nginx/client_temp && chown -Rv root:root /var/cache/nginx

CMD /bin/sh -c "envsubst < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
