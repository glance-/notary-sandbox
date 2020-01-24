all: up

up: init
	docker-compose -f docker-compose.yml up --remove-orphans

up_d: init
	docker-compose -f docker-compose.yml up -d --remove-orphans

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
	docker-compose -f docker-compose.yml -f docker-compose.init.yml rm -fv
	-docker volume rm notary_notary_data notary_signer_data

clean_fixtures:
	rm -f .generate_fixtures
	cd fixtures && rm -f intermediate-ca.crt notary-escrow.crt notary-escrow.key notary-server.crt notary-server.key notary-signer.crt notary-signer.key root-ca.crt secure.example.com.crt secure.example.com.key self-signed_docker.com-notary.crt self-signed_secure.example.com.crt

generate_fixtures: .generate_fixtures
.generate_fixtures:
	cd fixtures && ./regenerateTestingCerts.sh
	touch $@

run_registry:
	docker run --rm -p 5000:5000 -d --name registry registry
