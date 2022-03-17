# WireGuard dockerized
WireGuard in Docker

## Prequsites
You need any Debian-based VPS, wget, make, Docker

## Typical usage:
``` bash
apt-get install -y wget make
wget -O makefile https://raw.githubusercontent.com/chechulnikov/wg/main/makefile
wget -O dockerfile https://raw.githubusercontent.com/chechulnikov/wg/main/dockerfile

# install dependencies, generate WireGuard ./wghub.conf config for server
make init

# setup firewall
make firewall

# generate new client's configs for name 'macbook', 'iphone', etc
make client CLIENT=macbook
make client CLIENT=iphone

# ... copy clients configs from /wg directory and put it into your client app
cat /wg/wgclient_macbook.conf
cat /wg/wgclient_iphone.conf

# run WireGuard server
make run

# check status
make status
```

## Help
For checking all available commands just type
```
make
```
