FROM debian:11
RUN apt-get update && apt-get install -y nginx openssl gettext
EXPOSE 443
COPY nginx.conf /etc/nginx/nginx.conf
COPY openssl.cnf .
COPY script.sh .
COPY Server-Health-Dashboard.json .
RUN chmod +x script.sh
CMD ./script.sh
