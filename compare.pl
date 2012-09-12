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

print $query->header();

open (LOG, ">./log.html");

$bill1 = $query->param('b1');
$bill2 = $query->param('b2');

if(!$bill1 || !$bill2){
	die print "No bills!";
}

my @bill1_lines;
my @bill2_lines;
my @b1_lineIDs;
my @b2_lineIDs;


$| = 1;
print LOG "Getting Bills<br/>\n";


getBill($bill1,\@bill1_lines,\@b1_lineIDs);
getBill($bill2,\@bill2_lines,\@b2_lineIDs);

print LOG "Beginning Comparisons<br/>\n";




for(my $i=0;$i<@bill1_lines;$i++){
	for(my $j=0;$j<@bill2_lines;$j++){
	
		if(!$b1_lineIDs[$i] || !$b2_lineIDs[$j]){ # if it's null (don't know why) skip it
			next;
		}
		
		my $score = compareLines($bill1_lines[$i],$bill2_lines[$j]);
		
		if($score > .01){ # insert the score if it's significant
			insertScore($b1_lineIDs[$i],$b2_lineIDs[$j],$score);
		}
		
		if(($j%500) == 0){ # print an update every 500 compares
			print LOG "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$j lines...\n";
		}
	}
	print LOG "Line $b1_lineIDs[$i] analyzed<br/>\n";
}

sub getBill{
	my $l_bill_id = shift;
	my $lr_lines = shift;
	my $lr_lineIDs = shift;

	my $i=0;
	
	$sth = $dbh->prepare(qq{
		select line_id, line_text from bill_lines where leg_id = ?
	});
	$sth->execute($l_bill_id);
	while(($lr_lineIDs->[$i],$lr_lines->[$i]) = $sth->fetchrow_array()){
		$i++;
	}
	
	print LOG "Bill $l_bill_id retrieved - $i lines<br/>\n";
}


sub compareLines{ # splits into words, then sends to intersect to remove common words. What's left is what's not in common - then take the ratio of the amount of words before/after for the score
	my $l_line_left = shift;
	my $l_line_right = shift;
	
	my @words_left = split(/[\w\.\:\;\"\'\(\)]/, $l_line_left);
	my @words_right = split(/[\w\.\:\;\"\'\(\)]/, $l_line_right);
	
	my $length_before = @words_left + @words_right;
	intersect(\@words_left,\@words_right);
	my $length_after = @words_left + @words_right;
	
	if($length_before > 0){
		return (1-($length_after/$length_before));
	}else{
		return 0;
	}
	
}

sub intersect{
	my $lr_left = shift;
	my $lr_right = shift;
		
	OUTER: for(my $i=0;$i<@{$lr_left};$i++){
		for(my $j=0;$j<@{$lr_right};$j++){
			if($lr_left->[$i] eq $lr_right->[$j]){
				delete $lr_left->[$i];
				delete $lr_right->[$j];
				
				next OUTER;
			}
		}
	}
	
}

sub insertScore{
	my $line1 = shift;
	my $line2 = shift;
	my $score = shift;
	
	$sth = $dbh->prepare(qq{
		insert into line_comparisons (line_id1,line_id2,score) values (?,?,?)
	});
	$sth->execute($line1,$line2,$score) || print "Couldn't insert $line1, $line2, $score<br/>\n";
}