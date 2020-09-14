# docker-pgtde

## このリポジトリについて
[DockerhubのPostgreSQL9.6(apline)公式イメージ](https://github.com/docker-library/postgres/tree/master/9.6/alpine)をベースとして、NECの透過的暗号化機能「Transparent Data Encryption for PostgreSQL（以後PGTDE）」の導入までを自動化しました。

## 使い方
リポジトリをクローン後、以下を実行
```
docker-compose build
docker-compose up -d
```

## 詳細
 - ポートフォワードでホストPCの`15432`ポートを使用します。
 - PGTDEの暗号化キーはDockerfileの先頭で固定値で`NxFwsOzCoIij77JN`と定義しています。
 - 以下のファイルで`testdb`データベースを名指ししています。変更したい場合は以下すべて修正が必要です。
   - [Dockerfile](https://github.com/imo-tikuwa/docker-pgtde/blob/master/docker/postgres/Dockerfile)
   - [1_testdb_create_database.sql](https://github.com/imo-tikuwa/docker-pgtde/blob/master/docker/postgres/docker-entrypoint-initdb.d/1_testdb_create_database.sql)
   - [3_testdb_create_table.sql](https://github.com/imo-tikuwa/docker-pgtde/blob/master/docker/postgres/docker-entrypoint-initdb.d/3_testdb_create_table.sql)
   - [4_testdb_insert_data.sql](https://github.com/imo-tikuwa/docker-pgtde/blob/master/docker/postgres/docker-entrypoint-initdb.d/4_testdb_insert_data.sql)

## 参考
https://github.com/nec-postgres/tdeforpg/wiki/Manual(JA)

## memo
sample/dvdrental.tarをいったん9.6にインポート
```
docker cp sample\dvdrental.tar <コンテナID>:/
docker-compose exec postgres bash
pg_restore -U postgres -d testdb /dvdrental.tar
psql -U postgres testdb

psql (9.6.19)
Type "help" for help.

testdb=# \d
                     List of relations
 Schema |            Name            |   Type   |  Owner
--------+----------------------------+----------+----------
 public | actor                      | table    | postgres
 public | actor_actor_id_seq         | sequence | postgres
 public | actor_info                 | view     | postgres
 public | address                    | table    | postgres
 public | address_address_id_seq     | sequence | postgres
 public | category                   | table    | postgres
 public | category_category_id_seq   | sequence | postgres
 public | city                       | table    | postgres
 public | city_city_id_seq           | sequence | postgres
 public | country                    | table    | postgres
 public | country_country_id_seq     | sequence | postgres
 public | customer                   | table    | postgres
 public | customer_customer_id_seq   | sequence | postgres
 public | customer_list              | view     | postgres
 public | film                       | table    | postgres
 public | film_actor                 | table    | postgres
 public | film_category              | table    | postgres
 public | film_film_id_seq           | sequence | postgres
 public | film_list                  | view     | postgres
 public | inventory                  | table    | postgres
 public | inventory_inventory_id_seq | sequence | postgres
 public | language                   | table    | postgres
 public | language_language_id_seq   | sequence | postgres
 public | nicer_but_slower_film_list | view     | postgres
 public | payment                    | table    | postgres
 public | payment_payment_id_seq     | sequence | postgres
 public | rental                     | table    | postgres
 public | rental_rental_id_seq       | sequence | postgres
 public | sales_by_film_category     | view     | postgres
 public | sales_by_store             | view     | postgres
 public | staff                      | table    | postgres
 public | staff_list                 | view     | postgres
 public | staff_staff_id_seq         | sequence | postgres
 public | store                      | table    | postgres
 public | store_store_id_seq         | sequence | postgres
(35 rows)

\q
```

---
ダンプ取得
```
pg_dump -C -U postgres -s testdb > /1_testdb_ddl.sql
pg_dump -U postgres -a testdb > /2_testdb_data.sql
exit
```

---
ダンプをホストにコピー
```
docker cp <コンテナID>:/1_testdb_ddl.sql docker\postgres\docker-entrypoint-initdb.d
docker cp <コンテナID>:/2_testdb_data.sql docker\postgres\docker-entrypoint-initdb.d
```

---
ビルドに失敗したコンテナに名前を付けてアクセスする  
参考：https://qiita.com/mom0tomo/items/35dfacb628df1bd3651e
```
$ docker commit { コンテナID } { コンテナ名を適当に付ける }
$ docker run --rm -it { 適当につけたコンテナ名 } sh
```

---
最初にイメージの作成を行ってからコンテナを起動する
```
docker-compose up --build
```

## pgtdeについて手動でセットアップしたコンテナでの動作確認
cipher_setup.sh、cipher_key_regist.shを実行した後の動作確認 

<table><tr><td>cipher_key</td><td>NxFwsOzCoIij77JN</td></tr></table>

- 登録しておいた暗号化キーで暗号化セッションが開始できることを確認
- character型のカラムをENCRYPT_TEXT型に変更できることを確認
- 暗号化セッション中にENCRYPT_TEXT型のカラムを含むSELECTが行えることを確認
- 暗号化セッション中を終了した接続でENCRYPT_TEXT型のカラムを含むSELECTでエラーとなることを確認(TDE-E0017 could not decrypt data, because key was not set[01])
- 暗号化セッション中を終了した接続でENCRYPT_TEXT型のカラムを含まないSELECTが行えることを確認

```sql
$ psql -U postgres testdb

testdb=# select cipher_key_disable_log();
 cipher_key_disable_log 
------------------------
 t
(1 row)

testdb=# select pgtde_begin_session('NxFwsOzCoIij77JN');
 pgtde_begin_session
---------------------
 t
(1 row)

testdb=# select cipher_key_enable_log ();
 cipher_key_enable_log 
-----------------------
 t
(1 row)

testdb=# ALTER TABLE customer ALTER COLUMN email TYPE ENCRYPT_TEXT;
ALTER TABLE

testdb=# \d customer
                                          Table "public.customer"
   Column    |            Type             |                           Modifiers
-------------+-----------------------------+----------------------------------------------------------------
 customer_id | integer                     | not null default nextval('customer_customer_id_seq'::regclass)
 store_id    | smallint                    | not null
 first_name  | character varying(45)       | not null
 last_name   | character varying(45)       | not null
 email       | encrypt_text                |
 address_id  | smallint                    | not null
 activebool  | boolean                     | not null default true
 create_date | date                        | not null default ('now'::text)::date
 last_update | timestamp without time zone | default now()
 active      | integer                     |
Indexes:
    "customer_pkey" PRIMARY KEY, btree (customer_id)
    "idx_fk_address_id" btree (address_id)
    "idx_fk_store_id" btree (store_id)
    "idx_last_name" btree (last_name)
Foreign-key constraints:
    "customer_address_id_fkey" FOREIGN KEY (address_id) REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT
Referenced by:
    TABLE "payment" CONSTRAINT "payment_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT
    TABLE "rental" CONSTRAINT "rental_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT
Triggers:
    last_updated BEFORE UPDATE ON customer FOR EACH ROW EXECUTE PROCEDURE last_updated()

testdb=# select * from customer limit 3;
 customer_id | store_id | first_name | last_name |                email                | address_id | activebool | create_date |       last_update       | active 
-------------+----------+------------+-----------+-------------------------------------+------------+------------+-------------+-------------------------+--------
         524 |        1 | Jared      | Ely       | jared.ely@sakilacustomer.org        |        530 | t          | 2006-02-14  | 2013-05-26 14:49:45.738 |      1
           1 |        1 | Mary       | Smith     | mary.smith@sakilacustomer.org       |          5 | t          | 2006-02-14  | 2013-05-26 14:49:45.738 |      1
           2 |        1 | Patricia   | Johnson   | patricia.johnson@sakilacustomer.org |          6 | t          | 2006-02-14  | 2013-05-26 14:49:45.738 |      1
(3 rows)

testdb=# select pgtde_end_session();
 pgtde_end_session 
-------------------
 t
(1 row)

testdb=# select * from customer limit 3;
ERROR:  TDE-E0017 could not decrypt data, because key was not set[01]

testdb=# select customer_id, first_name from customer limit 3;
 customer_id | first_name 
-------------+------------
         524 | Jared
           1 | Mary
           2 | Patricia
(3 rows)

testdb=# select customer_id, email from customer limit 3;
ERROR:  TDE-E0017 could not decrypt data, because key was not set[01]
```
