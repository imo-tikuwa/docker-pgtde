#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
\connect $PGDATABASE;
select cipher_key_disable_log();
select pgtde_begin_session('$PGTDE_CIPHER');
select cipher_key_enable_log();

-- Please define the ALTER of the column you want to encrypt below.
ALTER TABLE customer ALTER COLUMN email TYPE ENCRYPT_TEXT;
ALTER TABLE staff ALTER COLUMN email TYPE ENCRYPT_TEXT;

select pgtde_end_session();
EOSQL