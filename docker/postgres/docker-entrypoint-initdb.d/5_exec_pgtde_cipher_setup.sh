#!/bin/bash
set -e

# 「Transparent Data Encryption for PostgreSQL」のセットアップ
# pgtdeのアクティベートを行う

sudo mv /tmp/init_cipher_setup.sh $TDEHOME/SOURCES/bin
cd $TDEHOME/SOURCES
expect -c "
set timeout 20
spawn sudo sh bin/init_cipher_setup.sh $PGHOME
expect \"select menu \[1 - 2\]\"
send -- \"1\n\"
expect \"Please enter database server port to connect :\"
send -- \"$PGPORT\n\"
expect \"Please enter database user name to connect :\"
send -- \"$PGUSER\n\"
expect \"Please enter password for authentication :\"
send -- \"$PGPASSWORD\n\"
expect \"Please enter database name to connect :\"
send -- \"$PGDATABASE\n\"
expect \"WARN: Transparent data encryption function has already been activated\"
send -- \x03
expect \"Please input \[Yes\/No\]\"
send -- \"Yes\n\"
expect \"INFO: Transparent data encryption feature has been activated\"
send -- \x03
expect \"psql: could not connect to server: Connection refused\"
send -- \x03
expect eof
"