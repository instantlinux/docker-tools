#! /usr/bin/perl

# Check Linux media settings using ethtool
# anders@fupp.net, 2007-09-19

use Getopt::Std;
getopts('i:s:d:a:hm');
$ENV{'PATH'} = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";

sub usage {
	print "Usage: check_ethtool [-i <interface>] [-s 10|100|1000|10000]\n";
	print "[-m (speed is minimum)] [-d <half|full>] [-a <on|off> (autoneg)] [-h (help)]\n";
	exit(1);
}

if ($opt_h) { usage; }

unless (defined($opt_a)) {
	$opt_a = "ignored";
}

# Assume full duplex
unless (defined($opt_d)) {
	$opt_d = "full";
}

if ($opt_i) {
	$if = $opt_i;
} else {
	# Try to guess interface name
	$iflist = `ip -o r get 8.8.8.8`;
	unless ($? == 0) { print "No ip command or problems with it? No interface specified with -i either.\n"; exit(2); }
	foreach $ifline (split(/\n/, $iflist)) {
		next if ($ifline =~ /bond/i);
		if ($ifline =~ /\s+dev\s+(\S+)/) {
			$if = $1;
			# Use first pick
			last;
		}
	}
	unless (defined($if)) {
		print "Could not find primary interface with ip command. No interface specified with -i either.\n"; exit(2);
	}
}

%modes = ();

$ethlines = "";
foreach $line (`ethtool $if 2>&1`) {
	chomp($line);
	$ethlines .= $line . "\n";
	if ($line =~ /^(\s+|)([\w -]+):\s+(\w+)/) {
		$key = $2;
		$val = $3;
		$key =~ s@\s@_@g;
		$key =~ tr@A-Z@a-z@;
		$val =~ tr@A-Z@a-z@;

		if ($key eq "speed") {
			$val =~ s@\D+@@g;
		}
		if ($key eq "auto-negotiation") {
			$key = "autoneg";
		}
		$modes{"$key"} = $val;
	}
}

if ($? != 0) {
	$ethlines =~ s@\n@ @g;
	$ethlines =~ s@\s{2,}@ @g;
	print "Ethtool exited with error: $ethlines\n";
	exit(2);
}

if ($opt_s) {
	$speed = $opt_s;
} else {
	$speed = 0;
#	if ($ethlines =~ /Advertised link modes:\s+(.*)\n\t\w/im) {
	if ($ethlines =~ /Supported link modes:\s+(.*?)\n\t\w/is) {
		# Grab modes over multiple lines
		$ethlines = $1;
		# Change any whitespace to space
		$ethlines =~ s@\s+@ @gs;
		# Strip non digits
		$ethlines =~ s@[^\d\s]@@g;
		foreach $sspeed (split(/\s+/, $ethlines)) {
			if ($sspeed > $curspeed) {
				$speed = $sspeed;
			}
		}
#		print "ethlines: $ethlines\n";
	}
}

if ($speed == 0) {
	print "Could not find supported link modes for interface $if. No speed defined with -s either.\n"; exit 2;
}

$speedok = 0;
if ($opt_m) {
	if ($modes{"speed"} >= $speed) {
		$speedok = 1;
	}
	$speedtxt = "minimum";
} else {
	if ($modes{"speed"} eq $speed) {
		$speedok = 1;
	}
	$speedtxt = "exact";
	
}

# Do not care about autoneg if it is not supported
if ($modes{"supports_auto-negotiation"} eq "no") {
	$opt_a = "ignored";
}

if ($speedok == 0 || $opt_d ne $modes{"duplex"} || ($opt_a ne "ignored" && $opt_a ne $modes{"autoneg"})) {
	print "Media settings error on $if. Expected $speed ($speedtxt) $opt_d autoneg=$opt_a, got " . $modes{"speed"} . " " . $modes{"duplex"} . " " . $modes{"autoneg"} . "\n";
	exit(2);
} else {
	print "Media settings OK on $if " . $modes{"speed"} . " ($speedtxt match with $speed) " . $modes{"duplex"} . " autoneg=" . $modes{"autoneg"};
	if ($opt_a eq "ignored") {
		print " (autoneg ignored)";
	}
	print "\n";
	exit(0);
}
