### Deploy configs
BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
project=walletconnect
redisImage='redis:5-alpine'
walletConnectImage='$(project)/relay:$(BRANCH)'

### Makefile internal coordination
flags=.makeFlags
VPATH=$(flags)

$(shell mkdir -p $(flags))

.PHONY: all clean default
define DEFAULT_TEXT
Available make rules:

pull:\tdownloads docker images

setup:\tconfigures domain an certbot email

build-relay:\tbuilds relay docker image

build:\tbuilds docker images

test-client:\truns client tests

relay-logs:\tdisplays relay logs

relay-watch:\truns relay on watch mode

relay-dev:\truns relay on watch mode and display logs

dev:\truns local docker stack with open ports

cloudflare: asks for a cloudflare DNS api and creates a docker secret

redeploy:\tredeploys to production

deploy:\tdeploys to production

deploy-monitoring:
\tdeploys to production with grafana

stop:\tstops all walletconnect docker stacks

upgrade:
\tpulls from remote git. Builds the containers and updates each individual
\tcontainer currently running with the new version that was just built.

reset:\treset local config

clean:\tcleans current docker build

clean-all:\tcleans current all local config

endef

log_end=@echo "MAKE: Done with $@"; echo

### Rules
export DEFAULT_TEXT
default:
	@echo -e "$$DEFAULT_TEXT"

pull:
	docker pull $(redisImage)
	docker pull nixos/nix
	@touch $(flags)/$@

setup:
	@read -p 'Relay URL domain: ' relay; \
	echo "RELAY_URL="$$relay > config
	@read -p 'Email for SSL certificate (default noreply@gmail.com): ' email; \
	echo "CERTBOT_EMAIL="$$email >> config
	@read -p 'Is your DNS configured with cloudflare proxy? [y/N]: ' cf; \
	echo "CLOUDFLARE="$${cf:-false} >> config
	@touch $(flags)/$@
	$(log_end)

build-container: volume
	rm -rf dist
	mkdir -p dist
	git archive --format=tar.gz -o dist/relay.tar.gz --prefix=relay/ HEAD
	docker run --name builder --rm \
		-v nix-store:/nix \
		-v $(shell pwd):/src \
		nixos/nix nix-shell \
		-p bash \
		--run \
		"nix-build \
		--argstr version $(BRANCH) \
		--argstr name $(project)/relay \
		/src/ops/relay-container.nix && \
		cp -L result /src/dist"
	docker load < dist/result
	@touch $(flags)/$@
	$(log_end)

volume:
	docker volume create nix-store
	$(log_end)

bootstrap:
	npm i
	npx lerna bootstrap
	@touch $(flags)/$@
	$(log_end)

build-relay: bootstrap
	npx lerna run build --scope=@walletconnect/relay-server --include-dependencies
	@touch $(flags)/$@
	$(log_end)

build-lerna: bootstrap
	npx lerna run build
	$(log_end)

build: pull build-lerna
	@touch $(flags)/$@
	$(log_end)

test-client:
	cd ./packages/client; npm run test; cd -

relay-logs:
	docker service logs -f --raw dev_$(project)_relay --tail 500

relay-dev: dev relay-watch relay-logs

relay-start: build-relay
	cd ./packages/relay; npm run start; cd -

watch-all:
	npx lerna run watch --stream

dev: pull build-container
	RELAY_IMAGE=$(walletConnectImage) \
	docker stack deploy \
	-c ops/docker-compose.yml \
	-c ops/docker-compose.dev.yml \
	dev_$(project)
	@echo  "MAKE: Done with $@"
	@echo


dev-monitoring: pull build-relay build-container
	RELAY_IMAGE=$(walletConnectImage) \
	docker stack deploy \
	-c ops/docker-compose.yml \
	-c ops/docker-compose.dev.yml \
	-c ops/docker-compose.monitor.yml \
	dev_$(project)
	@echo  "MAKE: Done with $@"
	@echo

cloudflare: setup
	bash ops/cloudflare-secret.sh $(project)
	@touch $(flags)/$@
	@echo  "MAKE: Done with $@"
	@echo

redeploy: 
	$(MAKE) clean
	$(MAKE) down
	$(MAKE) dev-monitoring

deploy: setup build-container cloudflare
	RELAY_IMAGE=$(walletConnectImage) \
	PROJECT=$(project) \
	bash ops/deploy.sh
	@echo  "MAKE: Done with $@"
	@echo

deploy-monitoring: setup build cloudflare
	RELAY_IMAGE=$(walletConnectImage) \
	PROJECT=$(project) \
	MONITORING=true \
	bash ops/deploy.sh
	@echo  "MAKE: Done with $@"
	@echo

down: stop

stop: 
	docker stack rm $(project)
	docker stack rm dev_$(project)
	while [ -n "`docker network ls --quiet --filter label=com.docker.stack.namespace=$(project)`" ]; do echo -n '.' && sleep 1; done
	@echo
	while [ -n "`docker network ls --quiet --filter label=com.docker.stack.namespace=dev_$(project)`" ]; do echo -n '.' && sleep 1; done
	@echo  "MAKE: Done with $@"
	@echo

upgrade: setup
	rm -f $(flags)/build*
	$(MAKE) build
	@echo  "MAKE: Done with $@"
	@echo
	git fetch origin $(BRANCH)
	git merge origin/$(BRANCH)
	docker service update --force $(project)_relay
	docker service update --force $(project)_redis

reset:
	$(MAKE) clean-all
	rm -f config
	@echo  "MAKE: Done with $@"
	@echo

clean:
	rm -rf .makeFlags/build*
	npx lerna run clean
	@echo  "MAKE: Done with $@"
	@echo

clean-all: clean
	npx lerna clean -y
	rm -rf .makeFlags
	rm -rf dist
	@echo  "MAKE: Done with $@"
	@echo
