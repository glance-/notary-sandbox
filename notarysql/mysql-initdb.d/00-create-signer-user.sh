#!/bin/bash

docker_process_sql <<< "CREATE USER 'signer'@'%' IDENTIFIED BY '$SIGNER_DB_SIGNER_PW';"
