ARG WG_PORT

FROM ubuntu:latest

RUN apt-get update

# install WireGuard
RUN apt-get install -y wireguard-tools mawk grep iproute2 qrencode wget iptables
RUN wget -O /easy-wg-quick https://raw.githubusercontent.com/burghardt/easy-wg-quick/master/easy-wg-quick 
RUN chmod +x /easy-wg-quick

WORKDIR /workdir