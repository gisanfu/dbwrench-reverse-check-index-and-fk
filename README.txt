Develop Environment

ubuntu 9.10
PostgreSQL 8.4.1
dbWrench 1.6.2

A target

several index or fk doesn't Reverse
i need to find it, and manual create

Depend package

sudo perl -MCPAN -e 'install DBI'
sudo perl -MCPAN -e 'install DBD:Pg'
sudo apt-get install libpq-dev

HOW TO USE

perl check.pl reverse-dbwrench-log.txt your_import_schema.sql
