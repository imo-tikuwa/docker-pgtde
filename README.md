# docker-pgtde

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
最初にイメージの作成も行って起動する
```
docker-compose up --build
```
