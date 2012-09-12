#!/usr/bin/perl

use DBI;
use CGI;

$query = new CGI;

my $db_name = '';
my $server = '';
my $dsn = 'DBI:mysql:$db_name:$server:$port';
my $db_user_name = '';
my $db_password = '';
$dbh = DBI->connect($dsn, $db_user_name, $db_password, { RaiseError => 1, AutoCommit => 0 }) || die print $query->header() . "could not connect to the database. Please try again later as the server may be overloaded";

@bills;
getList(\@bills);

print $query->header();

for(my $i=0;$i<@bills;$i++){
	my ($bill_id,$file) = addBill($bills[$i]);
	
	print "$bills[$i], $bill_id<br/>\n";
	my $contents;
	
	readBill($file, \$contents);
	parseFile(\$contents);

	insertLines(\$contents,$bill_id);
	writeBill($file,\$contents);
}

print "\n:";
$crap = <STDIN>;


sub getList{
	my $lr_bills = shift;

	open(CONFIG,"./config.txt");
	@{$lr_bills} = <CONFIG>;
	close (CONFIG);
	
	for(my $i=0;$i<@{$lr_bills};$i++){
		chomp($lr_bills->[$i]);
	}
}

sub addBill{
	my $l_bill_info = shift;

	my ($l_name,$l_file) = split(/ /, $l_bill_info);
	
	$sth = $dbh->prepare(qq{
		insert into legislation (name) values (?)
	});
	$sth->execute($l_name);
	
	$sth = $dbh->prepare(qq{
		select last_insert_id()
	});
	$sth->execute();
	my $bill_id = $sth->fetchrow_array();
	
	return $bill_id,$l_file;
}

sub insertLines{
	my $lr_contents = shift;
	my $bill_id = shift;
	
	my @content_lines = split(/\n/, $$lr_contents);
	
	for(my $i=0;$i<@content_lines;$i++){
		$sth = $dbh->prepare(qq{
			insert into bill_lines (line_number, line_text, leg_id) values (?,?,?)
		});
		$sth->execute($i,$content_lines[$i],$bill_id);
	}
}

sub writeBill{
	my $l_file = shift;
	my $lr_contents = shift;
	
	open(OUTF, ">./outputs/$l_file");
	print OUTF ${$lr_contents};
	close (OUTF);
}

sub readBill{
	my $l_file = shift;
	my $lr_contents = shift;;
	
	open(INF, "./inputs/$l_file");
	while(my $temp = <INF>){
		$$lr_contents .= $temp;
	}
	close(INF);
	
}

sub parseFile{
	my $lr_parse = shift;
	
	### begin filters
	
	$$lr_parse =~ s/\n *[\d]{0,3}/\n/ig; #remove line numbers
	$$lr_parse =~ s/^ *''//mg;
	$$lr_parse =~ s/\n{0,1}\s{0,3}\d{0,3}\s{0,3}\n/\n/ig; #remove lines that are page numbers
	$$lr_parse =~ s/\n{0,1}\s{0,3}O\:\\.+.xml[^\n]*\n/\n/ig; #remove O:\ crap
	
	$$lr_parse =~ s/^ *\(/{{REINSERT_NEWLINE}}\(/mg; #set a flag for "(" at newlines so that we can put a newline back here later
	$$lr_parse =~ s/^ *Sec\./{{REINSERT_NEWLINE}}Sec./mig; #set a flag for "Sec." at newlines so that we can put a newline back here later
	$$lr_parse =~ s/^ *TITLE/{{REINSERT_NEWLINE}}{{REINSERT_NEWLINE}}TITLE/mig; #set a flag for "TITLE" at newlines so that we can put a newline back here later
	$$lr_parse =~ s/^ *Section (\d)/{{REINSERT_NEWLINE}}Section \1/mig; 
	
	#$$lr_parse =~ s/([a-z])\d{1,2}\n/\1/ig; #remove line number at the end of lines and bring the next line up by removing the newline.
	$$lr_parse =~ s/([^\d])[1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28]\n/\1/ig; #remove line number at the end of lines and bring the next line up by removing the newline.
	$$lr_parse =~ s/(\s*)\n(\s*)/\1\2/g;
	$$lr_parse =~ s/{{REINSERT_NEWLINE}}/\n/g; #put newline back in where we had a flag
	
	### end filters
}


