COMPOSE_PROJECT=$(shell basename $(PWD))

all: up

up: init
	docker-compose -f docker-compose.yml up --remove-orphans

up_d: init
	docker-compose -f docker-compose.yml up -d --remove-orphans

testing_up: init
	docker-compose -f docker-compose.yml -f docker-compose.registry.yml -f docker-compose.notary-server-auth.yml up --remove-orphans

testing_up_d: init
	docker-compose -f docker-compose.yml -f docker-compose.registry.yml -f docker-compose.notary-server-auth.yml up -d --remove-orphans

.env:
	rm -f $@-new $@
	touch $@-new
	@echo generating passwords
	@for PW in NOTARY_SIGNER_PASSWORDALIAS1 NOTARY_DB_ROOT_PW NOTARY_DB_SERVER_PW SIGNER_DB_ROOT_PW SIGNER_DB_SIGNER_PW ; do \
		echo "$$PW=$$(pwgen -s 20 1)" >> $@-new ; \
	done
	mv $@-new $@

init: .init
.init: .env | generate_fixtures
	docker-compose -f docker-compose.yml -f docker-compose.init.yml up
	touch $@

down:
	docker-compose -f docker-compose.yml -f docker-compose.init.yml -f docker-compose.registry.yml -f docker-compose.notary-server-auth.yml down

stop:
	docker-compose -f docker-compose.yml -f docker-compose.init.yml -f docker-compose.registry.yml -f docker-compose.notary-server-auth.yml stop

clean:
	rm -f .init .env
	docker-compose -f docker-compose.yml -f docker-compose.init.yml -f docker-compose.registry.yml -f docker-compose.notary-server-auth.yml rm -sfv
	-docker volume rm $(COMPOSE_PROJECT)_notary_data $(COMPOSE_PROJECT)_signer_data $(COMPOSE_PROJECT)_registry_data

clean_fixtures:
	rm -f .generate_fixtures
	cd fixtures && rm -f intermediate-ca.crt notary-escrow.crt notary-escrow.key notary-server.crt notary-server.key notary-signer.crt notary-signer.key root-ca.crt secure.example.com.crt secure.example.com.key self-signed_docker.com-notary.crt self-signed_secure.example.com.crt registry-server.crt registry-server.key

generate_fixtures: .generate_fixtures
.generate_fixtures:
	cd fixtures && ./regenerateTestingCerts.sh
	touch $@

config_clients:
	mkdir -p ~/.notary/ ~/.docker/tls/notary-server
	cp notary_conf/config.json ~/.notary/
	cp fixtures/root-ca.crt ~/.docker/tls/notary-server/ca.crt
	cp fixtures/notary-server.crt ~/.docker/tls/notary-server/client.cert
	cp fixtures/notary-server.key ~/.docker/tls/notary-server/client.key

config_registry:
	sudo mkdir -p /etc/docker/certs.d/registry-server:5000
	sudo cp fixtures/root-ca.crt /etc/docker/certs.d/registry-server:5000/ca.crt

# We can't use any ip adress in 127.0.0.0/8 because docker doesn't care about certs when a ip resolves to that.
config_hosts:
	@printf "%s notary-server\n" $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' $(COMPOSE_PROJECT)_notaryserver_1) | sudo tee -a /etc/hosts
	@printf "%s notary-server\n" $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' $(COMPOSE_PROJECT)_notary-server-auth_1) | sudo tee -a /etc/hosts
	@printf "%s registry-server\n" $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' $(COMPOSE_PROJECT)_registry_1) | sudo tee -a /etc/hosts

client_env: .client_env
.client_env:
	rm -f $@-new $@
	touch $@-new
	for VAR in ROOT_PASSPHRASE TARGETS_PASSPHRASE REPOSITORY_PASSPHRASE SNAPSHOT_PASSPHRASE DELEGATION_PASSPHRASE ; do \
		PW="$$(pwgen -s 20 1)" ; \
		echo "NOTARY_$$VAR=$$PW" >> $@-new ; \
		echo "DOCKER_CONTENT_TRUST_$$VAR=$$PW" >> $@-new ; \
	done
	mv $@-new $@

DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE=
TEST_PUSH_TAG=latest

test_push_root: DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE=$(shell grep ^DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE .client_env)
test_push_root: test_push

test_push: client_env
	docker pull ubuntu:$(TEST_PUSH_TAG)
	docker tag ubuntu:$(TEST_PUSH_TAG) registry-server:5000/ubuntu:$(TEST_PUSH_TAG)
	env DOCKER_CONTENT_TRUST_SERVER=https://notary-server DOCKER_CONTENT_TRUST=1 $(DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE) $(shell grep ^DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE .client_env) docker push registry-server:5000/ubuntu:$(TEST_PUSH_TAG)
