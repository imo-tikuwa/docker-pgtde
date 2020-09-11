#!/bin/bash
set -e

# 「Transparent Data Encryption for PostgreSQL」のセットアップ
# pgtdeの暗号化セッションを開始するための暗号化キーを登録する

sudo mv /tmp/init_cipher_key_regist.sh $TDEHOME/SOURCES/bin
ls -al $TDEHOME/SOURCES/bin

cd $TDEHOME/SOURCES
expect -c "
set timeout 20
spawn sudo sh bin/init_cipher_key_regist.sh $PGHOME
expect \"Please enter database server port to connect :\"
send -- \"$PGPORT\n\"
expect \"Please enter database user name to connect :\"
send -- \"$PGUSER\n\"
expect \"Please enter password for authentication :\"
send -- \"$PGPASSWORD\n\"
expect \"Please enter database name to connect :\"
send -- \"$PGDATABASE\n\"
expect \"Please enter the new cipher key :\"
send -- \"$PGTDE_CIPHER\n\"
expect \"Please retype the new cipher key :\"
send -- \"$PGTDE_CIPHER\n\"
expect \"Please enter the algorithm for new cipher key :\"
send -- \"aes\n\"
expect \"Are you sure to register new cipher key(y\/n) :\"
send -- \"y\n\"
expect eof
"