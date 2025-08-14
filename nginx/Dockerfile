FROM debian:11
RUN apt-get update && apt-get install -y nginx openssl gettext
EXPOSE 443
COPY nginx.conf .
COPY openssl.cnf .
COPY script.sh .
RUN chmod +x script.sh
CMD ./script.sh