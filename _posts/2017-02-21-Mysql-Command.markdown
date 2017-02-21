####Mysql

#####1. 连接到 Mysql
连接到本机的 Mysql

```bash
$ mysql -u root -p                                                                                               ‹ruby-2.2.4›
Enter password:
```
连接到远程机器的 Mysql

```bash
mysql -h [机器IP] -u [用户名] -p [密码];
```
#####2. 创建数据库

```bash
mysql> drop database awesome;
Query OK, 1 row affected (0.01 sec)
```
分配用户

```
grant select, insert, update, delete on awesome.* to 'zzmbp'@'localhost' identified by 'passwd';
```

#####3. 显示数据库

```bash
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| awesome            |
| mysql              |
| performance_schema |
| test               |
+--------------------+
5 rows in set (0.00 sec)
```
#####4. 删除数据库

```bash
mysql> drop database awesome;
Query OK, 0 rows affected (0.00 sec)
```
删除一个不确定是否存在的数据库:

```
mysql> drop database if exists drop_database;
Query OK, 0 rows affected (0.00 sec)
```

#####5. 当前选择的数据库

```
mysql> select database();
+------------+
| database() |
+------------+
| awesome    |
+------------+
1 row in set (0.00 sec)
```