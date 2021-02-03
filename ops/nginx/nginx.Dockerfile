FROM nginx:1.19-alpine

RUN apk add --update --no-cache openssl-dev libffi-dev  musl-dev python3-dev py3-pip gcc openssl bash && \
  ln -fs /dev/stdout /var/log/nginx/access.log && \
  ln -fs /dev/stdout /var/log/nginx/error.log

RUN pip3 install certbot-dns-cloudflare

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./letsencrypt.conf /etc/nginx/letsencrypt.conf
COPY ./dhparams.pem /etc/letsencrypt/dhparams.pem
COPY ./entry.sh /entry.sh

RUN mkdir -p /etc/letsencrypt /run/secrets /etc/nginx /var/www /var/cache/nginx /var/log
RUN touch /run/nginx.pid
RUN chown nginx /entry.sh
RUN chown -R nginx:nginx /etc/nginx /run/nginx.pid /etc/letsencrypt /run/secrets /var/www /var/cache/nginx /var/log /var/lib/letsencrypt
USER nginx
ENTRYPOINT /entry.sh
