FROM nginx:stable-alpine

COPY nginx/html /usr/share/nginx/html
COPY nginx/default.conf.template /etc/nginx/conf.d/

CMD /bin/sh -c "envsubst < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
