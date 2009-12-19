#!/usr/bin/perl

# create: 2009-12-19
# author: gisanfu

# Environment
# dbwrench 1.5.2 or 1.6.2


# Action
# 1. get all fk from database
# 2. get all index from sql file
# 3. check dbwrench have fkname or indexname,
#    if not, then print them.

use DBI;
use Data::Dumper;

$dbname = 'database01_changeme';
$host = '' || '127.0.0.1';
$port = '' || '5432';
$username = 'dbuser_changeme';
$password = 'dbpass_changeme';

# this file is dbwrench reverse message log
$reverse_file = $ARGV[0] || '';

# sql file(INDEX is get from here)
$sql_file = $ARGV[1] || '';

if( $reverse_file eq '' or $sql_file eq '' ) {
    die 'ERROR: execute.pl [dbwrench-reverse-file] [sql-file]'."\n";
}

$dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port;", "$username", "$password");

$sql = 'SELECT
          tc.constraint_name
	    FROM 
	      information_schema.table_constraints AS tc 
	    JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
	    JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
		WHERE 
		  constraint_type = \'FOREIGN KEY\'';

$ref = $dbh->selectall_arrayref($sql);

if (defined ($ref)) {
    foreach my $row_ref (@{$ref}) {
		push @fks, $row_ref->[0];
    }
}


open SQLFILE, $sql_file or die $!; 
while(<SQLFILE>){
	if($_ =~ /create index (.*) on /i ){
		push @indexs, $1;
	}
}
close(SQLFILE);

open DBWRENCHFILE, $reverse_file or die $!; 
while(<DBWRENCHFILE>){
	#print $_."\n";
	push @reverselogs, $_;
}
close(DBWRENCHFILE);

for $fk (@fks){
	$found = 0;
	for $reverselog (@reverselogs){
		if( $reverselog =~ /^Added foreign key: $fk/ ){
			$found = 1;
		}
	}
	push @fkfails, $fk if $found eq 0;
}

print 'Total FK count in database: '.$#fks."\n";
print 'LOSS FK count in dbWrench Reverse: '.$#fkfails."\n";
print 'LOSS FK: '.$_."\n" for @fkfails;

for $index (@indexs){
	$found = 0;
	for $reverselog (@reverselogs){
		# Added Index: [schemas].[index name]
		if( $reverselog =~ /^Added Index: .*\.$index/ ){
			$found = 1;
		}
	}
	push @indexfails, $index if $found eq 0;
}

print 'Total INDEX count in sqlfile: '.$#indexs."\n";
print 'LOSS INDEX count in dbWrench Reverse: '.$#indexfails."\n";
print 'LOSS INDEX: '.$_."\n" for @indexfails;

