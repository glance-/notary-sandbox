#!/bin/bash

docker_process_sql <<< "CREATE USER 'server'@'%' IDENTIFIED BY '$NOTARY_DB_SERVER_PW';"
