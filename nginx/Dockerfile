FROM nginx:alpine
RUN apk add --no-cache openssl certbot
COPY entrypoint.sh /docker-entrypoint-custom.sh
RUN sed -i 's/\r$//' /docker-entrypoint-custom.sh && chmod +x /docker-entrypoint-custom.sh
COPY nginx.conf /etc/nginx/nginx.conf
ENTRYPOINT ["/docker-entrypoint-custom.sh"]
