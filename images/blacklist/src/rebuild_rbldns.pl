#!/usr/bin/perl
# rebuild_rbldns.pl
# Copyright (c) 2006 by Herb Rubin herbr@pfinders.com covered under GPL license
$version = "1.01"; # Mar 20, 2009
#
# Purpose: rebuild a flatfile of IP addresses from mysql ips table for RBL blacklist server
# Expects: database table named ips
#
# CREATE TABLE `ips` (
#  `ipaddress` varchar(15) NOT NULL default '',
#  `dateadded` datetime NOT NULL default '0000-00-00 00:00:00',
#  `reportedby` varchar(40) default NULL,
#  `updated` datetime default NULL,
#  `attacknotes` text,
#  `b_or_w` char(1) NOT NULL default 'b',
#  PRIMARY KEY  (`ipaddress`),
#  KEY `dateadded` (`dateadded`),
#  KEY `b_or_w` (`b_or_w`)
#) ENGINE=MyISAM DEFAULT CHARSET=latin1 COMMENT='spammer list';
#
# Begin User Defined Section
#----------------------------
my $dir            = $ENV{"HOMEDIR"} . "/" . $ENV{"CFG_NAME"};
my $blacklist_file = "$dir/spammerlist";
my $whitelist_file = "$dir/whitelist";
my $rbl_domain     = $ENV{"RBL_DOMAIN"};
my $my_cnf         = $ENV{"HOMEDIR"} . "/.my.cnf";
my $db             = $ENV{"DB_NAME"};
my $datasource     = "dbi:mysql:database=$db;mysql_read_default_file=$my_cnf";
my $temp_file      = "$dir/templist";
my $pid_file       = $ENV{"PID_FILE"};
#----------------------------
# End User Defined Section

$progname = $0;
$progname = $1 if ($progname =~ /([\w\._]+)$/); # trim off path
use Getopt::Std;
use DBI;
                                                                                
$pid = $$;
&getopts("fhvV",\%Options);
&usage if ($Options{'h'}); # then exit
my $changed = 0;
my $dbh;
                                                                                
if ($Options{"V"}) {
    print "$progname version $version\n";
    exit 0; # good exit
}
if ($dbh = DBI->connect($datasource, $mysql_user, $mysql_pass, { PrintError => 0, RaiseError => 0 }) ) {
    #########################
    # Logged in to database #
    #########################
    &build_file($blacklist_file, "b"); 
    &build_file($whitelist_file, "w");
    $dbh->disconnect;
} else {
    #################################
    # failed to connect to database #
    #################################
    print DBI->errstr . "\n" if ($Options{'v'});
    print "Error: Could not connect to local MySQL database. (did password change?)\n";
    exit 1; # bad exit
}
if ($changed) {
  &send_sighup($pid_file);
}
exit;

##########################
# subroutines start here #
##########################

sub usage {
    print <<EOF;
$progname usage:
                                                                                
   $progname [-hmtvV]

   Rebuild the rbl dns flat file from a mysql database.
   rbl means relay blacklist. 
   
   Recommendation: Run this as a cronjob on a regular basis.

 where:

    -h         Display this help
    -v         Verbose mode
    -V         Show $progname version.

EOF

}

sub build_file {
###########################################################
# create a file from mysql, either blacklist or whitelist #
###########################################################
  my ($file, $type) = @_;

  if (open RBL, ">$temp_file") {
      #########################################
      # first line of file is always the same #
      #########################################
      print RBL ":127.0.0.2:Known spammer, see http://$rbl_domain/index.php?id=\$\n";

      my $sql = "SELECT ipaddress FROM ips WHERE b_or_w='$type' ORDER BY dateadded, ipaddress";
      my $sth = $dbh->prepare($sql);
      $sth->execute;
      my $count = 0;
      while ($hash_ref   = $sth->fetchrow_hashref) {
         my $ipaddress   = $$hash_ref{'ipaddress'};
         #my $dateadded   = $$hash_ref{'dateadded'};
         #my $reportedby  = $$hash_ref{'reportedby'};
         #my $updated     = $$hash_ref{'updated'};
         #my $attacknotes = $$hash_ref{'attacknotes'};
         #my $borw        = $$hash_ref{'borw'};
         $count ++;
         if ($type eq "w") {
             print RBL "!$ipaddress\n";
         } else {
             print RBL "$ipaddress\n";
         }
      }
      close RBL;
      `diff -q $temp_file $file`;
      if ($?) {
        `mv $temp_file $file`;
	$changed = 1;
      }
      print "$count ips of type $type\n" if ($Options{'v'});
  } else {
      print "Failed to open $file for writing\n";
  }
}

sub send_sighup() {
###########################################################
# send SIGHUP signal to rbldnsd                           #
###########################################################
  my $pidfile = @_;
  if (open PID, "< $pidfile") {
    my $pid = <PID>;
    close PID;

    kill 1, $pid;
    die "Lock held by PID $pid!\n" if $! == Errno::ESRCH;
  }
}
