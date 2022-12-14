#!/bin/bash

postgres_ready() {
python << END
import sys

import psycopg2

try:
    psycopg2.connect(
        dbname="${PG_DB_NAME}",
        user="${PG_USER}",
        password="${PG_PASS}",
        host="${PG_HOST}",
        port="${PG_PORT}",
    )
except psycopg2.OperationalError:
    sys.exit(-1)
sys.exit(0)

END
}

echo '=> TEST DATABASE CONECTION'
until postgres_ready; do
  >&2 echo '=> Waiting for PostgreSQL to become available...'
  sleep 1
done
>&2 echo '=> PostgreSQL is available'

echo "=> Performing database migrations..."
python manage.py migrate

echo "=> Collecting static files..."
python manage.py collectstatic --noinput

echo "=> Compiling translations..."
python manage.py compilemessages

echo "=> Starting webserver..."
gunicorn --bind 0.0.0.0:5000 -w 8 src.wsgi:application 