-- some setting to make the output less verbose
\set QUIET on
\set ON_ERROR_STOP on
set client_min_messages to warning;

begin;
\set authenticator `echo $DB_USER`
\set authenticator_pass `echo $DB_PASS`
drop role if exists :authenticator;
create role :authenticator with login password :'authenticator_pass';

-- this is an applciation level role
-- requests that are not authenticated will be executed with this role's privileges
drop role if exists anonymous;
create role anonymous;
grant anonymous to :authenticator;

-- this is the main role used by authenticated users of our application
drop role if exists webuser;
create role webuser;
grant webuser to :authenticator;
    
-- app secrets
\set jwt_secret `echo $JWT_SECRET`
\set quoted_jwt_secret '\'' :jwt_secret '\''

commit;
