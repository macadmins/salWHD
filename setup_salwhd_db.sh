#!/bin/sh
DB_NAME=sal
DB_USER=saldbadmin
DB_PASS=password

echo "CREATE TABLE casperimport(id INT PRIMARY KEY NOT NULL, serial TEXT, name TEXT, model TEXT, ios_version TEXT, ipaddress TEXT, macaddress TEXT, bluetooth TEXT, capacity TEXT, username TEXT, email TEXT, asset_tag TEXT);" | docker run \
  --rm \
  --interactive \
  --link postgres-sal:postgres \
  postgres:latest \
  bash -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres'
