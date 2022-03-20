SS_CLIENT_PORT = 5634
SS_PSW = lazy-elephant3

WG_PORT = 28832
SS_PORT = 28833

DIR = /wgss

IMAGE = wg
CONTAINER = wg

SERVER_IP = $(shell ip addr sh "eth0" | grep 'inet ' | xargs | awk -F'[ /]' '{ print $$2 }')

define DOCKERFILE
FROM ubuntu:latest

RUN apt-get update

# install WireGuard
RUN apt-get install -y wireguard-tools mawk grep iproute2 qrencode wget iptables
RUN wget -O /easy-wg-quick https://raw.githubusercontent.com/burghardt/easy-wg-quick/master/easy-wg-quick 
RUN chmod +x /easy-wg-quick

# install Shadowsocks
RUN apt-get install -y shadowsocks-libev haveged

WORKDIR /workdir
endef
export SS_SERVER_CONFIG

define SS_SERVER_CONFIG
{
    "server": "0.0.0.0",
    "server_port": $(SS_PORT),
    "password": "$(SS_PSW)",
    "timeout": 300,
    "method": "chacha20-ietf-poly1305",
    "mode": "tcp_and_udp"
}
endef
export SS_SERVER_CONFIG

define SS_CLIENT_CONFIG
{
  "server": "$(SERVER_IP)",
  "server_port": $(SS_PORT),
  "local_address": "0.0.0.0",
  "local_port": $(SS_CLIENT_PORT),
  "password": "$(SS_PSW)",
  "timeout": 300,
  "method": "chacha20-ietf-poly1305",
  "mode": "tcp_and_udp",
  "tunnel_address": "127.0.0.1:$(WG_PORT)"
}
endef
export SS_CLIENT_CONFIG


.DEFAULT_GOAL = help

help:		# prints this help
	@ echo → Available targets are:
	@ grep -h -E "^[^\#].+:\s+\#\s+.+$$" ./makefile
	
install:		# install dependencies
	@ apt-get update
	@ apt-get install -y docker.io htop needrestart speedtest-cli wget sed grep iptables

init:		# build Docker image, generate WireGuard and Shadowsock configs for server
	# build Docker image
	@ echo $${SS_SERVER_CONFIG} > ./dockerfile
	@ make build
	@ rm -f ./dockerfile

	@ mkdir $(DIR)

	# setup WireGuard configs for easy-wg-quick util
	# create extnetip.txt from which easy-wg-quick reads maschine's IP
	@ echo $(SERVER_IP) > $(DIR)/extnetip.txt 
	# create portno.txt from which easy-wg-quick reads WireGuard port
	@ echo $(WG_PORT) > $(DIR)/portno.txt

	# setup Shadowsocks config
	@ echo $${SS_SERVER_CONFIG} > $(DIR)/ss-server.json
	@ echo $${SS_CLIENT_CONFIG} > $(DIR)/ss-client.json

	@ make _run COMMAND='/easy-wg-quick'
	@ make stop
	
build:		# build Docker image
	@ docker build \
		-t $(IMAGE) \
		--build-arg WG_PORT=$(WG_PORT) \
		-f ./dockerfile \
		.

run:		# run WireGuard + Shadowsocks server from ./wghub.conf
	@ make _run COMMAND='wg-quick up ./wghub.conf'
	@ make _run COMMAND='ss-server -c ./ss-server.json &'

client:		# generate new client config for name $(CLIENT)
	@ make _run COMMAND='/easy-wg-quick $(CLIENT)'
	@ make stop

	# fix up WireGuard's client endpoint in client's config
	@ sed -i '' \
		's/Endpoint = $(SERVER_IP):$(WG_PORT)/Endpoint = 127.0.0.1:$(SS_CLIENT_PORT)/' \
		$(DIR)/wgclient_$(CLIENT).conf

status:		# displays WireGuard status
	@ docker exec -it $(CONTAINER) wg show

stop:		# kill docker container
	@ docker rm -f $(CONTAINER)

clean:		# clean environment
	@ make stop
	@ docker rmi -f $(IMAGE)
	@ rm -r $(DIR)

firewall:	# setup firewal: allow only WireGuard, Shadowsocks and SSH ports and deny all others
	@ ufw disable
	@ ufw default deny incoming
	@ ufw allow $(WG_PORT)/tcp 
	@ ufw allow $(WG_PORT)/udp
	@ ufw allow $(SS_PORT)/tcp 
	@ ufw allow $(SS_PORT)/udp
	@ ufw allow ssh
	@ ufw enable

restart:	# restart maschine
	@ halt —-reboot

_run:		# run Docker $(CONTAINER) from $(IMAGE) with $(COMMAND)
	@ docker run -d -it \
		--restart unless-stopped \
		--privileged \
		--name $(CONTAINER) \
		-v $(DIR):/workdir \
		-w /workdir \
		-p $(WG_PORT):$(WG_PORT)/tcp \
		-p $(WG_PORT):$(WG_PORT)/udp \
		-p $(SS_PORT):$(SS_PORT)/tcp \
		-p $(SS_PORT):$(SS_PORT)/udp \
		$(IMAGE)
	@ docker exec -it $(CONTAINER) $(COMMAND)
