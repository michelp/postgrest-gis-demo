# Minimal example of getting a PostgREST API running from scratch for
# testing purposes.  It uses docker to launch a postgres database and
# a postgrest api server.

# This should not be used to deploy a production system but to
# understand how postgrest works.  In particular there is no security
# implemented, see the docs for more.

# https://postgrest.org/en/v4.4/

# For a more complete starter kit including openresty, see
# https://github.com/subzerocloud/postgrest-starter-kit

# this script requires docker, curl, and jq

DB_HOST="db"
DB_NAME="postgres"
DB_SCHEMA="api"
DB_USER="authenticator"
DB_PASS="authenticatorpass"
DB_ANON="anonymous"
DB_PORT="9876"  # port to bind on docker host
DB_BIND="$DB_PORT":5432

API_HOST="api"
API_PORT="3000"  # port to bind on docker host
API_BIND="$API_PORT":3000

POSTGRES_SU="postgres"
POSTGRES_SU_PASSWORD="mysecretpassword"

echo pulling and running postgres
docker pull postgres
docker run --name "$DB_HOST" \
       -e POSTGRES_PASSWORD="$POSTGRES_SU_PASSWORD" \
       -d "$DB_NAME"

echo waiting for database to accept connections
until
    docker exec "$DB_HOST" \
	   psql -o /dev/null -t -q -U "$POSTGRES_SU" -c 'select pg_sleep(1)' -d "$DB_NAME" \
	   2>/dev/null;
do sleep 1;
done

echo database is ready to connect, creating model
docker exec -i "$DB_HOST" psql -U "$POSTGRES_SU" -d "$DB_NAME" <<EOF
create schema api;

create table api.todos (
  id serial primary key,
  done boolean not null default false,
  task text not null,
  due timestamptz
);

insert into api.todos (task) values
  ('get groceries'), ('feed dog');

create role $DB_USER login;
alter role $DB_USER password '$DB_PASS';

create role $DB_ANON nologin;
grant $DB_ANON to $DB_USER;

grant usage on schema api to $DB_ANON;
grant select, insert, update, delete on api.todos to $DB_ANON;
grant usage, select on all sequences in schema api to $DB_ANON;
EOF

echo pulling and running postgrest api server
docker pull subzerocloud/postgrest
docker run --name "$API_HOST" --link "$DB_HOST" -p "$API_BIND" \
       -e PGRST_DB_URI=postgres://"$DB_USER":"$DB_PASS"@"$DB_HOST"/"$DB_NAME" \
       -e PGRST_DB_SCHEMA="$DB_SCHEMA" \
       -e PGRST_DB_ANON_ROLE="$DB_ANON" \
       -d subzerocloud/postgrest

sleep 1

echo GET to SELECT from todos
curl -s localhost:"$API_PORT"/todos | jq .

echo POST to INSERT a todo
curl -s -H "Content-Type: application/json" \
     -d '{"task":"weed the garden"}' \
     localhost:"$API_PORT"/todos

echo PATCH to UPDATE a todo
curl -X PATCH  -s -H "Content-Type: application/json" \
     -d '{"due": "2018-06-01"}' \
     'localhost:"$API_PORT"/todos?id=eq.1'

echo showing final changes
curl -s localhost:"$API_PORT"/todos | jq .
