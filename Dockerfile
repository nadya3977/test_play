FROM nginx:stable-alpine

WORKDIR /usr/share/nginx/html
COPY index.html /usr/share/nginx/html/