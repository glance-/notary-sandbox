all: up

up: init
	docker-compose -f docker-compose.yml up --remove-orphans

up_d: init
	docker-compose -f docker-compose.yml up -d --remove-orphans

registry_up: init
	docker-compose -f docker-compose.yml -f docker-compose.registry.yml up --remove-orphans

registry_up_d: init
	docker-compose -f docker-compose.yml -f docker-compose.registry.yml up -d --remove-orphans

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
	docker-compose -f docker-compose.yml -f docker-compose.init.yml -f docker-compose.registry.yml rm -sfv
	-docker volume rm notary_notary_data notary_signer_data notary_registry_data

clean_fixtures:
	rm -f .generate_fixtures
	cd fixtures && rm -f intermediate-ca.crt notary-escrow.crt notary-escrow.key notary-server.crt notary-server.key notary-signer.crt notary-signer.key root-ca.crt secure.example.com.crt secure.example.com.key self-signed_docker.com-notary.crt self-signed_secure.example.com.crt registry-server.crt registry-server.key

generate_fixtures: .generate_fixtures
.generate_fixtures:
	cd fixtures && ./regenerateTestingCerts.sh
	touch $@

config_registry:
	sudo mkdir -p /etc/docker/certs.d/registry-server:5000
	sudo cp fixtures/root-ca.crt /etc/docker/certs.d/registry-server:5000/ca.crt

# We can't use any ip adress in 127.0.0.0/8 because docker doesn't care about certs when a ip resolves to that.
config_hosts:
	@printf "%s registry-server\n" $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' notary_registry_1) | sudo tee -a /etc/hosts
