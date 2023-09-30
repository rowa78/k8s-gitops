# admin user
create user ronny with password '*********';
grant admin to ronny;

#application user
create user eve with password '********';
create database eve owner eve;


create user bar with password 'bar';
create database bar owner bar;