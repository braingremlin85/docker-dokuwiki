# docker-dokuwiki

minimal alpine based image with apache2 and php-fpm82 with dokuwiki pre-installed

.env file get bypassed by manually set environment variables from portainer gui


## Build #

sudo docker buildx build --platform linux/amd64,linux/arm64 -t braingremlin/dokuwiki:latest -t braingremlin/dokuwiki:librarian --push .

## Networking ##
If you are using a reverse proxy on the same container environment you should set a common network for the proxy and all the proxied services, so you can access those services directly by docker internal network using the container name, i.e.:

`http://mycontainer:80`

**use the EXPOSED port not the PUBLISHED!**



```yaml
services:
  mycontainer:
    container_name: mycontainer
    .
    .
    .
    networks:
      - npm-bridge
    ports:
      - ${EXTERNAL_PORT:-8888}:80 # use 80 instead of EXTERNAL_PORT to access this service from internal docker network

networks:
  npm-bridge:
    name: npm_bridge
```
