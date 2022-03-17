WG_PORT = 28832

WG_DIR = /wg

IMAGE = wg
CONTAINER = wg

.DEFAULT_GOAL = help

help:		# prints this help
	@ echo → Available targets are:
	@ grep -h -E "^[^\#].+:\s+\#\s+.+$$" ./makefile

build:		# build Docker image
	@ docker build \
		-t $(IMAGE) \
		--build-arg WG_PORT=$(WG_PORT) \
		-f ./dockerfile \
		.

init:		# install dependencies and generate WireGuard ./wghub.conf config for server
	@ apt-get update
	@ apt-get install -y docker.io htop needrestart speedtest-cli wget
	@ make build
	@ mkdir $(WG_DIR)
	# create extnetip.txt from which easy-wg-quick reads maschine's IP
	@ ip addr sh "eth0" | grep 'inet ' | xargs | awk -F'[ /]' '{ print $$2 }' > $(WG_DIR)/extnetip.txt 
	# create portno.txt from which easy-wg-quick reads WireGuard port
	@ echo $(WG_PORT) >> $(WG_DIR)/portno.txt 
	@ make _run COMMAND='/easy-wg-quick'
	@ make stop

run:		# run WireGuard server from ./wghub.conf
	@ echo → Run se
	@ make _run COMMAND='wg-quick up ./wghub.conf'

client:		# generate new client config for name $(CLIENT)
	@ echo → Add client $(CLIENT)
	@ make _run COMMAND='/easy-wg-quick $(CLIENT)'
	@ make stop

status:		# displays WireGuard status
	@ docker exec -it $(CONTAINER) wg show

_run:		# run Docker $(CONTAINER) from $(IMAGE) mwith $(COMMAND)
	@ docker run -d -it \
		--restart unless-stopped \
		--privileged \
		--name $(CONTAINER) \
		-v $(WG_DIR):/workdir \
		-w /workdir \
		-p $(WG_PORT):$(WG_PORT)/tcp \
		-p $(WG_PORT):$(WG_PORT)/udp \
		$(IMAGE)
	@ docker exec -it $(CONTAINER) $(COMMAND)

stop:		# kill docker container
	@ docker rm -f $(CONTAINER)

clean:		# clean environment
	@ make stop
	@ docker rmi -f $(IMAGE)
	@ rm -r $(WG_DIR)

firewall:	# setup firewal: allow only WireGuard and SSH ports and deny all others
	@ ufw disable
	@ ufw default deny incoming
	@ ufw allow $(WG_PORT)/tcp 
	@ ufw allow $(WG_PORT)/udp
	@ ufw allow ssh
	@ ufw enable

restart:	# restart maschine
	@ halt —-reboot
