FROM nginx:alpine

COPY index.html.template /usr/share/nginx/html/index.html.template
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
