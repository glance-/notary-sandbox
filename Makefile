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
	docker-compose -f docker-compose.yml -f docker-compose.init.yml down

stop:
	docker-compose -f docker-compose.yml -f docker-compose.init.yml stop

clean:
	rm -f .init .env
	docker-compose -f docker-compose.yml -f docker-compose.init.yml -f docker-compose.registry.yml -f docker-compose.notary-server-auth.yml rm -sfv
	-docker volume rm notary_notary_data notary_signer_data notary_registry_data

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
	@printf "%s notary-server\n" $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' notary_notaryserver_1) | sudo tee -a /etc/hosts
	@printf "%s notary-server\n" $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' notary_notary-server-auth_1) | sudo tee -a /etc/hosts
	@printf "%s registry-server\n" $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' notary_registry_1) | sudo tee -a /etc/hosts
