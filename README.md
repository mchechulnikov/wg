# WireGuard dockerized
WireGuard in Docker

## Prequsites
You need any Debian-based VPS with Docker

## Typical usage:
``` bash
apt-get install -y wget make
wget -O makefile https://raw.githubusercontent.com/chechulnikov/wg/main/makefile
wget -O dockerfile https://raw.githubusercontent.com/chechulnikov/wg/main/dockerfile

# generate WireGuard ./wghub.conf config for server
make init

# generate new client's configs for name 'macbook', 'iphone', etc
make client $(CLIENT)=macbook
make client $(CLIENT)=iphone

# ... copy clients configs from /wg directory and put it into your client app

# run WireGuard server
make run
```
