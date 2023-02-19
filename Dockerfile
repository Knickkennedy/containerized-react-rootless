# Fetching the latest node image on apline linux
FROM docker.io/library/node:alpine AS builder

RUN apk update \
    && apk add jq

# Setting up the work directory
WORKDIR /app
COPY . .

RUN jq 'to_entries | map_values({ (.key) : ("$" + .key) }) | reduce .[] as $item ({}; . + $item)' ./src/config.json > ./src/config.tmp.json && mv ./src/config.tmp.json ./src/config.json
# Declaring env
ENV NODE_ENV production

RUN npm install && npm run build

# Fetching the latest nginx image
FROM docker.io/library/nginx

ENV JSFOLDER=/usr/share/nginx/html/static/js/*.js
COPY ./nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /opt/app && chown -R nginx:nginx /opt/app && chmod -R 755 /opt/app
RUN chown -R nginx:nginx /var/cache/nginx && \
   chown -R nginx:nginx /var/log/nginx && \
   chown -R nginx:nginx /etc/nginx/conf.d
RUN touch /var/run/nginx.pid && \
   chown -R nginx:nginx /var/run/nginx.pid  
RUN chgrp -R root /var/cache/nginx /var/run /var/log/nginx /var/run/nginx.pid && \
   chmod -R 755 /var/cache/nginx /var/run /var/log/nginx /var/run/nginx.pid
COPY ./start-nginx.sh /usr/bin/start-nginx.sh
RUN chmod +x /usr/bin/start-nginx.sh

USER nginx
WORKDIR /opt/app

# Copying built assets from builder
COPY --from=builder /app/build .

ENTRYPOINT [ "start-nginx.sh" ]