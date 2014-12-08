#!/bin/sh
DB_NAME=jssimport
DB_USER=jssdbadmin
DB_PASS=password

echo "CREATE ROLE $DB_USER WITH LOGIN ENCRYPTED PASSWORD '${DB_PASS}' CREATEDB;" | docker run \
  --rm \
  --interactive \
  --link postgres-sal:postgres \
  grahamgilbert/postgres:latest \
  bash -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres'

echo "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0 ENCODING 'UTF8';" | docker run \
  --rm \
  --interactive \
  --link postgres-sal:postgres \
  grahamgilbert/postgres:latest \
  bash -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres'

echo "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" | docker run \
  --rm \
  --interactive \
  --link postgres-sal:postgres \
  grahamgilbert/postgres:latest \
  bash -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres'


echo "CREATE TABLE casperimport(id INT PRIMARY KEY NOT NULL, serial TEXT, name TEXT, model TEXT, ios_version TEXT, ipaddress TEXT, macaddress TEXT, bluetooth TEXT, capacity TEXT, username TEXT, email TEXT, asset_tag TEXT);" | docker run \
  --rm \
  --interactive \
  --link postgres-sal:postgres \
  grahamgilbert/postgres:latest \
  bash -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -d $DB_NAME -U postgres'
