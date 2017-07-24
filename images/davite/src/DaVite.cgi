#!/usr/bin/perl
# Filename:	DaVite.cgi
# Author:	David Ljung Madison <DaveSource.com>
# See License:	http://MarginalHacks.com/License
# Version:	1.15
# Description:	Web invitation system, much like evite! or Yahoo! invites.
#		Creates web invites and mails it to all of your guests
#		who can then read all the details and respond online.
use strict;
use Fcntl;	# For sysopen flags
use POSIX;	# For mktime

umask 0022;

##################################################
##################################################
#
# SETTINGS (you probably want to change these)
#
##################################################
##################################################

## The name of your machine (with optional :port)
my $HOST = "{{ HOSTNAME }}";

## If you're using SSL, here's where you choose "https:"
my $HTTP = "{{ SCHEME }}";

## Leave HTTP_PORT blank, or prefix port by colon, such as :8080
my $HTTP_PORT = "{{ TCP_PORT }}";

## The location of the cgi script (we might be guessing it if
## the REFERER not specified)
my $CGI = $ENV{REQUEST_URI} || "/cgi-bin/DaVite.cgi";
   $CGI =~ s/[\&\?][^\/]+$//;

## A URL path to the DaVite directory.
##
## If this path is relative, it needs to be from whatever directory the server
## runs CGI scripts from.  If you're not sure, run CGI with this uncommented:
##
#ERROR("PWD is: ".`/bin/pwd`);
##
## (Or just use an absolute URL)
##
## Either way, you should be able to view this path in your web browser
##
## Common examples:  "DaVite"  "../DaVite"  "http://www.DaVite.com/DaVite/"
my $DAVITE_URL =	"{{ URL_PATH }}";

## Now figure out the actual filesystem path that you would use from a shell
## to access the DaVite directory.  You should be able to "ls/dir" this path.
##
## This is probably the same as $DAVITE_URL, but not if you use absolute paths
## or if your cgi-bin directory is aliased under httpd.
##
## Common examples:  "DaVite"  "../DaVite"  "/home/httpd/docs/DaVite"
my $DAVITE_DIR =	"{{ SRCDIR }}";

## A path to the DaVite_Data directory - this should be an absolute path and
## should *NOT* be inside your web root (i.e., NOT accessible from the web).
## You should be able to "ls/dir" to this path from a shell prompt.
##
## You shouldn't be able to view this directory from your website!
my $DATA_DIR =		"{{ DATADIR }}";

## SMTP smarthost
my $SMTP_SMARTHOST =    "{{ SMTP_SMARTHOST }}";
my $SMTP_PORT =         "{{ SMTP_PORT }}";

## Map links are automatically generated for addresses.  If they don't
## specify a city or state, use:
my $DEFAULT_CITY	= "San Francisco";
my $DEFAULT_STATE	= "CA";

## What email addresses are allowed to create new invites?  (list of regexps)
#my @CAN_CREATE	= ();					# Nobody
my @CAN_CREATE	= qw(.);				# Everybody
#my @CAN_CREATE	= qw(\@.*$HOST);			# Everybody at this host
#my @CAN_CREATE	= qw(dave\@DaVite.com \@.*$HOST);	# .. and me too.  :)

## Maximum number of invitees to show at a time (before 'next ..' link)
my $MAXSHOW = 40;

## If you have the Sendmail.pm package, you might want to use it.
## If you do, we won't use the sendmail binary (below).
## Plus:  The CGI will be able to tell you if mailings succeed or not.
## Minus: Sendmail.pm doesn't use forge_pipe, so email won't look right.
##
## The Sendmail.pm package is required and implied on Windows systems!
##
##   You can get Sendmail.pm easily via:
## CPAN:            perl -MCPAN -e "install Mail::Sendmail"
## ActivePerl ppm:  ppm install --location=http://alma.ch/perl/ppm Mail-Sendmail
## Manually:        <<copy Sendmail.pm to Mail/ in your perl lib directory>>
##
my $USE_SENDMAIL_PM	= 0;

#########################
# Where is sendmail? (forge_pipe is best!)
#
# I *highly* recommend using forge_pipe so it can properly "forge" the
# email messages to be from the invite author, and not from your httpd user!
#########################
#my $SENDMAIL	= "/usr/bin/forge_pipe";  # See http://MarginalHacks.com/#forge
my $SENDMAIL	= "/usr/sbin/sendmail";
#  $SENDMAIL	= "/usr/sbin/sendmail" if (! -x $SENDMAIL);
   $SENDMAIL	= "/usr/lib/sendmail" if (! -x $SENDMAIL);
   $SENDMAIL	= "/usr/bin/sendmail" if (! -x $SENDMAIL);

##################################################
##################################################
#
# Code
#
##################################################
##################################################
# These you probably shouldn't change
##################################################
my $URL = "${HTTP}://$HOST$HTTP_PORT$CGI";

#########################
# Under Windows?  (Use Sendmail.pm instead)
# $^O: Win98->MSWin, WinXP->MSWin, CygWin->cygwin, but OSX is "darwin" - yeesh.
#########################
my $OSX = ($^O =~ /darwin/i) ? 1 : 0;
my $CRAPPY_OS = (!$OSX && ($^O =~ /Win/i)) ? 1 : 0; 
# The Sendmail.pm package is required and implied on Windows systems!
$USE_SENDMAIL_PM = 1 if $CRAPPY_OS;

require Mail::Sendmail if $USE_SENDMAIL_PM;

my $EVENTS =		"$DATA_DIR/Events";
my $NAMES =		"$DATA_DIR/Names";
my $THEMES_URL =	"$DAVITE_URL/Themes";
my $THEMES_DIR =	"$DAVITE_DIR/Themes";
my $BACKGROUNDS_URL =	"$DAVITE_URL/Backgrounds";
my $BACKGROUNDS_DIR =	"$DAVITE_DIR/Backgrounds";
my $PICS =		"$DAVITE_URL/Pics";

# Use javascript to hide mailto links so they can't be gathered by spammers
my $OBSCURE_MAILTO = 1;

##################################################
# Query
##################################################
sub from_url {
  my ($str) = @_;
  $str =~ s/\+/ /g;
  $str =~ s/%([0-9a-f]{2})/chr(hex($1))/eig;
  $str;
}

sub to_url {
  my ($str) = @_;
  $str =~ s/([^ a-zA-Z0-9\.])/"%".sprintf("%0.2x",ord($1))/eg;
  $str =~ s/ /+/g;
  $str;
}

sub unhtml {
  my ($str) = @_;
  $str = from_url($str);
  $str =~ s/</\&lt;/g;
  $str =~ s/>/\&gt;/g;
  $str =~ s/[\r\n]/ /g;
  $str;
}

sub html {
  my (@str) = @_;
  my $str = join("<br>\n",split("\n",join("",@str)));
  $str;
}

sub parse_query {
  # Get query
  my $query_string;
  if ($ENV{REQUEST_METHOD} eq "POST") {
    read(STDIN,$query_string,$ENV{CONTENT_LENGTH});
  } elsif ($ENV{QUERY_STRING}) {
    $query_string = $ENV{QUERY_STRING};
  } elsif (@ARGV) {
    $query_string = join("&",@ARGV);
  }
  chomp($query_string);

  # Split query
  # $query_string is of the form:  "variable=value&var2=val2&.."
  my @querys=split(/[\&\?]/,$query_string);
  my (%query,$var,$val);
  foreach my $str (@querys) {
    $var = $str if (!(($var,$val) = ($str =~ /([^=]*)=(.*)/)));
    $val = 1 unless defined $val;
    $query{$var} = from_url($val);
  }

#header(1); show_values(\%query);
  \%query;
}

sub show_values {
  my ($query) = @_;
  print "<p><hr><p>\n\n";
  foreach my $q ( keys %$query ) {
    print " Value: $q -> $query->{$q}<br>\n";
  }
}

##################################################
# HTML
##################################################
my $DID_HEADER=0;

sub header {
  my ($light,$background) = @_;

  $background = $background ? "background=$background" : "";

  return if $DID_HEADER++;
  print "Content-type: text/html\n\n";
  return if $light;
print <<GOBBLE_HEADER;
<html>
</head>
<title>DaVite Invitation System</title>
</head>

<body $background bgcolor=white>

<table bgcolor=black width=100%><tr><td align=right>
  <font size=+1 color=yellow>
    DaVite Invitation System
  </font>
</td></tr></table>

<br>
GOBBLE_HEADER
}

sub ERROR { header(); print "<h2>ERROR: @_</h2>\n"; undef; }

sub footer {
  return unless $DID_HEADER;
  print <<GOBBLE_FOOTER;

  <p><hr><p>

  <table width=100%>
    <tr>
      <td valign=bottom align=left>
        <font color=#996622>
          <a href=http://MarginalHacks.com/Hacks/DaVite/>DaVite</a> software created by <a href=http://MarginalHacks.com/>MarginalHacks</a>
        </font>
      </td>
      <td align=right>
        <a href=http://MarginalHacks.com/
           onMouseOver = document.images['MarginalHacks'].src='$PICS/MarginalHacks_down.gif'
            onMouseOut = document.images['MarginalHacks'].src='$PICS/MarginalHacks.gif'
           onMouseDown = document.images['MarginalHacks'].src='$PICS/MarginalHacks_down.gif'
             onMouseUp = document.images['MarginalHacks'].src='$PICS/MarginalHacks.gif'>
        <img name=MarginalHacks alt="MarginalHacks.com - I have an elegant script for that, but it's too small to fit in the margin."
             src=$PICS/MarginalHacks.gif
             width=69 height=60 border=0></a>

        <a href=http://GetDave.com/
           onMouseOver = document.images['GetDave'].src='$PICS/GetDave_down.gif'
            onMouseOut = document.images['GetDave'].src='$PICS/GetDave.gif'
           onMouseDown = document.images['GetDave'].src='$PICS/GetDave_down.gif'
             onMouseUp = document.images['GetDave'].src='$PICS/GetDave.gif'>
        <img name=GetDave alt="GetDave.com - Dave's Domain hub."
             src=$PICS/GetDave.gif
             width=69 height=60 border=0></a>
      </td>
    </tr>
  </table>

</body>
</html>
GOBBLE_FOOTER
}

##################################################
# People code
##################################################
#my $MESSAGE;
my $MY_INVITE = 0;
my %NICK;	# Cache the email->name hash
my %HIDE;	# Cache email->hide
sub read_names {
  return \%NICK if %NICK;
  open(N,"<$NAMES") || return \%NICK;
  my ($email,$hide,$name);
  while (<N>) {
    chomp;
    if (($email,$hide,$name) = split(/\t/,$_,3)) {
      $NICK{$email} = $name;
      $HIDE{$email} = $hide;
    }
  }
  close N;
  \%NICK;
}

sub write_names {
  my ($attempt) = @_;

  # (For blocking open)
  sleep 1 if ($attempt>4);
  return ERROR("Couldn't write new name - try again?") if ($attempt>6);

  my $new = "$NAMES.new";

  # Blocking open
  sysopen(N, $new, O_WRONLY | O_EXCL | O_CREAT) || return write_names($attempt+1);

  foreach my $email (keys %NICK) {
    print N "$email	$HIDE{$email}	$NICK{$email}\n";
  }
  close N;
  # This could be serious because it could leave behind an old ".new" file
  # which will block new writes...
  if (!rename($new,$NAMES) && !my_sys("/bin/mv $new $NAMES")) {
    ERROR("Couldn't overwrite namelist! [$NAMES]");
    unlink($new) || ERROR("And couldn't remove new namelist!  Trouble!");
  }
}

my $NICK;	# Cache the email->name hash
sub get_name {
  my ($email) = @_;
  read_names();
  $NICK{$email} || $email;
}

sub hide_email {
  my ($email) = @_;
  read_names();
  $HIDE{$email} ? 1 : 0;
}

sub set_name {
  my ($email,$new_name,$new_hide) = @_;
  read_names();
  $NICK{$email} = unhtml($new_name);
  $HIDE{$email} = $new_hide ? 1 : 0;
  write_names();
}

sub lookup_email {
  my ($guid,$guests) = @_;
  $guests->{$guid}{email} || undef;
}

sub lookup_guid_by_email {
  my ($email,$guests) = @_;
  foreach my $guid ( keys %$guests ) {
    # Assume that email is case-insensitive.  Worst case
    # is that "AB@hello.com" will be able to lookup invites for "ab@hello.com"
    # but best case is no confusion here..
    return $guid if lc($guests->{$guid}{email}) eq lc($email);
  }
  return undef;
}

sub lookup_name {
  my ($guid,$guests) = @_;

  my $email = lookup_email($guid,$guests);
  return undef unless $email;
  get_name($email);
}

sub lookup_guid_link {
  my ($guid,$guests) = @_;

  my $email = lookup_email($guid,$guests);
  return "<i>unknown?</i>" unless $email;
  my $name = get_name($email);
  return $name if (!$MY_INVITE && $HIDE{$email} && $name ne $email);

# RB - this is for privacy
  return $name;

  return "<a href=mailto:$email>$name</a>" unless $OBSCURE_MAILTO;

  my ($e1,$e2) = ($email =~ /(.*)(\@.*)/) ? ($1,$2) : ("",$email);
  my ($n1,$n2) = ($name =~ /(.*)(\@.*)/) ? ($1,$2) : ($name,"");

  "<a href=mailto:$e1--$e2>$n1--$n2</a>";
  return <<OBSCURE;
<script>
<!--
document.write("<a href=mai"+"lto:$e1"+"$e2>$n1");
document.write("$n2</a>");
//-->
</script>
OBSCURE
}

sub read_guests {
  my ($ev) = @_;
  my ($y,$n,$m,$u,%g) = (0,0,0,0);

  open(G,"<$EVENTS/${ev}/Guests") || return ERROR("Couldn't read guestlist [$EVENTS/$ev]");
  while (<G>) {
    chomp;
    my ($email,$guid,$ynm,$plus_guests,$comments,$reply_time,@answers) = split(/\t/,$_);
    next unless $guid;
    $g{$guid}{email} = $email;
    $ynm = "U" unless $ynm;
    $g{$guid}{ynm} = $ynm;
    $ynm eq "Y" ? $y+=1+$plus_guests : $ynm eq "M" ? $m+=1+$plus_guests : $ynm eq "N" ? $n++ : $u++;
    $g{$guid}{plus_guests} = $plus_guests || 0;
    $g{$guid}{comments} = $comments;
    $g{$guid}{reply_time} = $reply_time;
    @{$g{$guid}{answers}} = @answers;
  }
  close G;
  ($y,$n,$m,$u,\%g);
}

sub write_guests {
  my ($event,$guests,$attempt) = @_;

  # (For blocking open)
  sleep 1 if ($attempt>4);
  return ERROR("Couldn't write new guestlist [$EVENTS/$event]") if ($attempt>6);

  my $old = "$EVENTS/$event/Guests";
  my $new = "$old.new";

  # Blocking open
  sysopen(G, $new, O_WRONLY | O_EXCL | O_CREAT)
    || return write_guests($event,$guests,$attempt+1);

  foreach my $guid ( keys %$guests ) {
    my $g = $guests->{$guid};
    my $ans = join("\t",@{$g->{answers}}) if $g->{answers};
    print G "$g->{email}\t$guid\t$g->{ynm}\t$g->{plus_guests}\t$g->{comments}\t$g->{reply_time}\t$ans\n";
  }
  close G;
  if (!rename($new,$old) && !my_sys("/bin/mv $new $old")) {
    ERROR("Couldn't overwrite new guestlist [$EVENTS/$event]");
    unlink($new) || ERROR("And couldn't remove new guestlist!  Trouble!");
  }
}

##################################################
# Theme code
##################################################
sub replace_error { my ($str) = @_; "<font color=red><i><b>$str</b></i></font>"; }

# Replace <: ... :> inside themes:
# 1)  <: =$var :>    or   <: =var :>
# 2)  <: =! $var :>	(Don't return "unknown var...")
# 3)  <: = @var :>
# 4)  <: function :>
sub get_var {
  my ($var,$ev,$vars,$array) = @_;
  $var = lc($var);

  my $val = undef;
  $val = $ev->{$var} if defined $ev->{$var} && (!$array || ref ($ev->{$var}) eq "ARRAY");
  $val = $vars->{$var} if defined $vars->{$var} && (!$array || ref ($vars->{$var}) eq "ARRAY");
  $val = join("",@$val) if $val && $array;

  return show_form($var,$val)
    if ($vars->{EDIT} && ($var eq "notes" || $var eq "caption"));
  return html($val);
}

sub theme_replace {
  my ($str,$ev,$guests,$vars,$edit) = @_;

  # Remove leading/trailing whitespace and case
  $str =~ s/^\s+//; $str =~ s/\s+$//; $str = lc($str);

  # Array var?
  if ($str =~ /^=(!)?\s*(\$|\@)?(\S.*)$/) {
    my ($var,$unknown,$array) = ($3, $1?1:0, $2 eq "@" ?1:0);
    $str = get_var($var,$ev,$vars,$array);
    return $str if defined $str;
    return "" if $unknown;
    return replace_error("unknown ".($array?"array ":"")."var [$var]");
  }

  # Must be sub
  return toolbar($ev,$guests,$vars) if ($str eq "toolbar");
  return show_details($ev,$guests,$vars) if ($str eq "show_details");
  return show_guests($ev,$guests,$vars) if ($str eq "show_guests");
  return reply_here($ev,$guests,$vars) if ($str eq "reply_here");

  return replace_error("unknown sub [$str]");
}

sub test_if {
  my ($if,$ev,$vars) = @_;

  $if =~ s/^\s*(\$|\@)?//;
  my $array = $1 eq "@" ? 1 : 0;
  get_var($if,$ev,$vars,$array) ? 1 : 0;
}

sub file_select {
  my ($var,$val,$url,$dir) = @_;
  my $r = "<select name=$var>";
  if (opendir(DIR,$dir)) {
    my @files = grep(-f "$dir/$_", readdir(DIR));
    closedir(DIR);
    foreach my $f ( @files ) {
      my $name = $f;  $name =~ s/_/ /g;  $name =~ s/\.[^\.\/]+$//;
      $r .= "<option ".(($val eq "$url/$f")?"selected ":"")."value='$url/$f'>$name</option>";
    }
  }
  $r .= "</select>";
  return $r;
}

sub show_form {
  my ($var,$val) = @_;

  # Special fields (menus)
  if (grep($var eq $_, qw(allow_invites allow_invite_me send_me_responses))) {
    my $r = "<select name=$var>";
    $r .= "<option ".(($val==1)?"selected ":"")."value=1>yes</option>";
    $r .= "<option ".(($val==0)?"selected ":"")."value=0>no</option>";
    $r .= "</select>";
    return $r;
  }

  return file_select($var,$val,$BACKGROUNDS_URL,$BACKGROUNDS_DIR) if $var eq "background";
  return file_select($var,$val,$THEMES_URL,$THEMES_DIR) if $var eq "theme";

  # Generic field - either input or textarea
  my $lines = split(/(<br>|\n)/g,$val) - 1;
  $lines = 15 if $lines > 15;
  $lines = 10 if (($lines<10) && $var eq "notes");
  $lines = 3 if (($lines<3) && $var eq "caption");
  if ($lines<2) {
    $val =~ s/"/&quot;/g;
    return "<input type=text name=$var size=17 value=\"$val\">";
  }

  my $cols = ($lines > 7) ? 50 : 25;
  my $r = "<textarea name=$var rows=$lines cols=$cols wrap=soft>$val</textarea>";
  return $r unless $var eq "notes" || $var eq "caption";
  return <<TEXTAREA
<font size=+1>$var:</font><br>
$r
<input type=submit name=edit_event value='Save Changes'>
TEXTAREA
}

# 0=okay, 1=not readable, 2=not exists
sub check_path {
  my ($p) = @_;
  my @p = split(/\//, $p);
  my $path;
  foreach ( @p ) {
    $path.="$_/";
    return 2 unless -d $path;
    return 1 unless -r $path;
  }
  0;
}

sub show_theme {
  my ($ev,$guests,$vars) = @_;

  # Read the theme
  my $theme = $ev->{theme};
  $theme =~ s/^$THEMES_DIR\/?//;
  $theme =~ s|.*/||g;

  # Prepare for failure - have a good suggestion ready
  my $suggest;
  my $check_path = check_path($THEMES_DIR);
  if ($check_path==2) {
    $suggest = "Incorrect \$THEMES_DIR setting: [$THEMES_DIR]";
    if (-x "/bin/pwd") {
      my $pwd = `/bin/pwd`;  chomp($pwd);
      $suggest .= "<p>\$THEMES_DIR=<tt>$THEMES_DIR</tt><br>but <tt>$pwd/$THEMES_DIR</tt> does not exist\n";
    }
  } elsif ($check_path==1) {
    $suggest = "Theme directory [$THEMES_DIR] not readable by web user.  Try making it globally readable?";
  } elsif (! -f "$THEMES_DIR/$theme") {
    $suggest = "Theme doesn't exist - try a different theme? [$theme]<br>".
               "Either edit the DaVite_Data/Event/&lt;num&gt;/Details file manually,".
               "or else try creating a new event";
  } elsif (! -r "$THEMES_DIR/$theme") {
    $suggest = "Theme not readable by web user.  Try making it globally readable?";
  } else {
    $suggest = "Unknown error??";
  }

  open(THEME,"<$THEMES_DIR/$theme") || return ERROR("Couldn't read theme [$theme]<p>$suggest");
  my @theme=<THEME>;
  close(THEME);

  # Setup form defaults
  if ($vars->{guid}) {
    my $ynm = $guests->{$vars->{guid}}{ynm};
    $vars->{Ychecked} = $ynm eq "Y" || $ynm eq "U" ? "checked" : "";
    $vars->{Nchecked} = $ynm eq "N" ? "checked" : "";
    $vars->{Mchecked} = $ynm eq "M" ? "checked" : "";
  }

  # Write the theme out
  header(1);
  my @if = (1);
  for (my $line=1; $line<=$#theme+1; $line++) {
    $_ = $theme[$line-1];

    # Variables and simple replacements
    s/<:(.+?):>/theme_replace($1,$ev,$guests,$vars)/eg if $if[0];

    # if/else/endif statements
    if (/(.*)<\?\s*(.+?)\s*\?>(.*)/) {
      my ($pre,$cond,$post) = ($1,$2,$3);
      print $pre if ($if[0]);
      if ($cond =~ /^if\s*(.*)$/i) {
        unshift(@if, $if[0] ? test_if($1,$ev,$vars) : 0 );
      } elsif ($cond =~ /^\s*else\s*$/) {
        $if[0] = !$if[0];
      } elsif ($cond =~ /^\s*endif/i) {
        ERROR("[line $line] Too many endif") unless $#if;
        shift(@if) if $#if;
      }
      $_ = $post;
    }
    print if $if[0];
  }
}

##################################################
# Event code
##################################################
sub maybe_delete_event {
  my ($ev) = @_;
  my $event = $ev->{ID};

  # Last mod to the event (Details or Guests)
  my $mod_details = -M "$EVENTS/$event/Details";
  my $mod_guests = -M "$EVENTS/$event/Guests";
  my $mod = ($mod_guests && $mod_guests < $mod_details) ? $mod_guests : $mod_details;

  # Guess if it's empty
  my $empty = ($ev->{event_name} || $ev->{day} || $ev->{when}) ? 0 : 1;

  # Delete events that are:
  # >1 day old and empty
  # >1 year old
  return 0 unless (($mod>1 && $empty) || $mod>365);

  # My own little safe rm -R
  opendir(DIR,"$EVENTS/$event") || return 0;
  my @dir = grep(!/^\.{1,2}$/, readdir(DIR));
  closedir DIR;

  foreach ( @dir ) {
    return print "(trouble deleting event [$event/$_])"
      unless unlink "$EVENTS/$event/$_";
  }
  return print "(trouble deleting event [$event])"
    unless rmdir "$EVENTS/$event";

  print "[old - deleted]\n";
  return 1;
}

sub empty_query {
  header();

#  # This MouseOver stuff will only work on >=IE4.0.  Damn!
#  print <<EMAIL_CREATE if @CAN_CREATE;
#<form action=$URL method=GET name=create>
#  <input type=hidden name=create value=1>
#  Email: <input type=text name=email size=20 maxlength=200>
#  <input type=image name=Create_Invite src=$PICS/Create_Invite.gif
#           alt="Create an invite" width=69 height=19
#           onMouseOver = document.images['Create_Invite'].src='$PICS/Create_Invite.down.gif'
#            onMouseOut = document.images['Create_Invite'].src='$PICS/Create_Invite.gif'
#           onMouseDown = document.images['Create_Invite'].src='$PICS/Create_Invite.down.gif'
#             onMouseUp = document.images['Create_Invite'].src='$PICS/Create_Invite.gif'>
#</form>

# But this works in general!  Thanks, Timothy Kilpatrick <tkigd.com>
  print <<EMAIL_CREATE if @CAN_CREATE;
<form action=$URL method=GET name=create>
  <input type=hidden name=create value=1>
  Email: <input type=text name=email size=20 maxlength=200>
  <a href="javascript:document.create.submit()"
       onMouseOver = document.images['Create_Invite'].src='$PICS/Create_Invite.down.gif'
       onMouseOut = document.images['Create_Invite'].src='$PICS/Create_Invite.gif'
       onMouseDown = document.images['Create_Invite'].src='$PICS/Create_Invite.down.gif'
       onMouseUp = document.images['Create_Invite'].src='$PICS/Create_Invite.gif'>
   <img src=$PICS/Create_Invite.gif alt="Create an invite" width=69 height=19 name=Create_Invite border=0>
  </a>
</form>

<p>
or:
<p>

<form action=$URL method=GET name=get_invites>
  <input type=hidden name=get_invites value=1>
  Email: <input type=text name=email size=20 maxlength=200>
  Send me all my invites.
</form>
EMAIL_CREATE

  opendir(EVENTS,$EVENTS) || return ERROR("Couldn't read events [$EVENTS]");
  my @events = grep(!/^\.{1,2}$/ && -d "$EVENTS/$_" && -f "$EVENTS/$_/Details", readdir(EVENTS));
  closedir(EVENTS);

  print "<h2>Event List</h2>\n<ol>\n";
  foreach my $event ( @events ) {
    my $ev = read_event($event);
    my $name = $ev->{event_name} || "(empty invite)";
    print "<li> <a href=$URL?event=$event>$name</a>\n";
    print "[$ev->{month}/$ev->{day}/$ev->{year}]\n" if $ev->{day};
    maybe_delete_event($ev);
    print "<br>\n";
  }
  print "</ol>\n";
}

sub read_event {
  my ($event) = @_;
  my %ev;
  $ev{ID} = $event;
  open(EV,"<$EVENTS/$event/Details") || return ERROR("Event [$event] is no longer in our database");
  while (<EV>) {
    chomp;
    if (/^--$/) {
      $ev{notes} .= join("",<EV>);
      last;
    }
    if (/^(\S+):\s*(\S?.*)$/ && lc($1) ne "notes") {
      if ($ev{lc($1)}) {
        $ev{lc($1)} .= "\n$2";
      } else {
        $ev{lc($1)} = $2;
      }
    } else {
      $ev{notes} .= "$_\n";
    }
  }
  close EV;
  $ev{event_name_text} = strip_html($ev{event_name});
  \%ev;
}

sub write_event {
  my ($ev,$attempt) = @_;

  my $old = "$EVENTS/$ev->{ID}/Details";
  my $new = "$old.new";
           
  # (For blocking open)
  sleep 1 if ($attempt>4);
  return ERROR("Couldn't write new event [$new] - try again?") if ($attempt>6);
  sysopen(N, $new, O_WRONLY | O_EXCL | O_CREAT) || return write_event($ev,$attempt+1);
  foreach my $var ( keys %$ev ) {
    next if ($var eq "notes");
    next if ($var =~ /[A-Z]/);		# Uppercase are for internal vars
    print N "$var: \n" unless $ev->{$var};
    foreach ( split(/\n/, $ev->{$var}) ) {
      print N "$var: $_\n";
    }
  }
  print N "--\n";
  print N $ev->{notes};
  close N;

  if (!rename($new,$old) && !my_sys("/bin/mv $new $old")) {
    ERROR("Couldn't overwrite event details! [$old]");
    unlink($new) || ERROR("And couldn't remove new detail file!  Trouble!");
  }
}

sub return_link {
  my ($event,$guid,$timeout) = @_;
  print "Click <a href=$URL?event=$event&guid=$guid>here</a> to return to the invite\n";
  return if $timeout == -1;
  $timeout = 1 unless $timeout;
  $timeout *= 1000;
  $guid = "&guid=$guid" if $guid;

print <<RELOC;
<SCRIPT language="JavaScript">
<!--
setTimeout('reloc()',$timeout);
function reloc() { window.location="$URL?event=$event$guid"; }
//-->
</SCRIPT>
RELOC
}

sub my_sys { my ($cmd) = @_;  system($cmd);  $?==0?1:0; }

# Order these keys first, in this order
my @KEYS = qw(host phone when month day year time where address city state zip);
# For new events
my @MORE_KEYS = qw(background send_me_responses allow_invites allow_invite_me event_name image caption theme notes);

my %KEYS;
for (my $i=0; $i<=$#KEYS; $i++) { $KEYS{$KEYS[$i]} = $i+1; }
sub key_pos { my ($k) = @_; $KEYS{$k}; }
sub sort_keys {
  my $pa = key_pos($a);
  my $pb = key_pos($b);
  if ($pa) {
    if ($pb) {
      return $pa <=> $pb;
    } else {
      return -1;
    }
  } else {
    if ($pb) {
      return 1;
    } else {
      return $a cmp $b;
    }
  }
}

sub show_map {
  my ($ev) = @_;
  my $zip = " $ev->{zip}" if $ev->{zip};
  my $city = $ev->{city} || $DEFAULT_CITY;
  my $state = $ev->{state} || $DEFAULT_STATE;
  my $url = "http://maps.yahoo.com/py/maps.py?Country=us&addr=$ev->{address}&csz=$city $state$zip";
  #my $url = "http://www.mapblast.com/mblast/map.mb?loc=us&CMD=GEO&AD2=$ev->{address}&AD3=$city $state$zip";
  $url =~ s/ /+/g;

#  $url =~ s/,/%2C/g;
  # Heck, do everything!
  $url =~ s/([^a-zA-Z0-9+:\/\.\?\&\=])/sprintf("%%%2.2x",ord($1))/eg;

  "<a target=_new href='$url'>$ev->{address}</a>";
}

sub show_when {
  my ($ev) = @_;

  my $mday = $ev->{day};
  my $mon = $ev->{month};
  my $year = $ev->{year};

  return "??" unless $mday;

  my ($a,$now_mon,$now_year);
  ($a,$a,$a,$a,$now_mon,$now_year,$a,$a,$a) = localtime(time);

  # Guess month if missing
  $mon = $now_mon+1 unless $mon;
  $year = $now_year+1900 unless $year;

           # mktime(sec, min, hour, mday, mon, year, wday, yday, isdst)
  my $when = mktime(0,0,24,$mday,$mon-1,$year-1900,0,0,0);
  my $now = time;

  # Might be next year?
  if ($when < $now && !$ev->{year}) {
    $year++;
    $when = mktime(0,0,24,$mday,$mon-1,$year-1900,0,0,0);
  }

  my $date = (qw(January February March April May June July August September October November December))[$mon-1];
  $date .= " $mday, $year";

  my $till = "";
  if ($when-$now>0) {
    my $days_left = int(($when-$now)/(60*60*24));
    return "$date (today!)" unless $days_left;
    return "$date (tomorrow!)" if $days_left == 1;
    if ($days_left < 70) {
      my $weeks_left = int($days_left/7);
      $days_left -= $weeks_left*7;
      $till = "<br><font size=-1>(";
      $till .= "$weeks_left week" if $weeks_left;
      $till .= ($weeks_left>1) ? "s " : ($weeks_left) ? " " : "";
      $till .= "$days_left day" if $days_left;
      $till .= ($days_left>1) ? "s " : ($days_left) ? " " : "";
      $till .= "left)<font>";
    }
  }

  "$date$till";
}

sub show_details {
  my ($ev,$guests,$vars) = @_;

  my @details;
  if ($vars->{EDIT}) {
    @details = (@KEYS,@MORE_KEYS);
    @details = grep($_ ne "notes" && $_ ne "caption" && $_ ne "event_name" && $_ ne "event_name_text" && $_ ne "when", @details);
  } else {
    @details = sort sort_keys keys %$ev;
    @details = grep(!/[A-Z]/, @details);	# Uppercase are for internal vars
    @details = grep($_ ne "notes" && $_ ne "theme" && $_ ne "event_name" && $_ ne "event_name_text" &&
                    $_ ne "allow_invites" && $_ ne "allow_invite_me" && $_ ne "send_me_responses" &&
                    $_ ne "image" && $_ ne "background" && $_ ne "caption" &&
                    $_ ne "day" && $_ ne "month" && $_ ne "year" && $_ ne "when" &&
                    $_ ne "state" && $_ ne "city" && $_ ne "zip", @details);
    @details = grep($_ ne "address", @details) if (grep($_ eq "where", @details));
    push(@details,"when");
  }


  print "<table width=100%>\n";
  # Name and notes
  my $rowspan = $#details+2;
  $rowspan++ if $vars->{EDIT};	# For the "Save Changes" button
  print "<tr valign=top>\n";
  print "<td width=2% rowspan=$rowspan>&nbsp;</td>\n";
  print "<th align=right>Event:</th>\n";
  print "<td width=4% rowspan=$rowspan>&nbsp;</td>\n";
  print "<td>";
  if ($vars->{EDIT}) {
    print show_form("event_name",$vars->{event_name});
  } else {
    print $vars->{event_name};
  }
  print "</td></tr>\n";

  foreach my $var ( @details ) {
    my $val = $ev->{$var};
    if ($vars->{EDIT} && $var ne "host") {
      $val = show_form($var,$val);
    } else {
      $val = html($val);
      $val = show_map($ev) if ($var eq "address");
      $val .= "<br>".show_map($ev) if ($var eq "where" && $ev->{address});
      $val = show_when($ev) if ($var eq "when");
      $val = lookup_guid_link($val,$guests) if ($var eq "host");
    }
    print "<tr valign=top><th align=right>$var:</th><td>$val</td></tr>\n";
  }
  print "<tr><th></th><td align=right><input type=submit name=edit_event value='Save Changes'></td></tr>\n"
    if ($vars->{EDIT});

  print "</table>\n";

  "";	# Theme subs print what they return..
}

# Only guests that match a specific ynm
sub show_guests_match {
  my ($ev,$guests_L,$guests,$match,$vars) = @_;

  my $maxshow = $vars->{maxshow} || $MAXSHOW;
  my $total = lc($match);
  $total = $vars->{$total};
  my $start = $vars->{start} || 1;
  $start=$total-$maxshow if ($start>$total);
  $start=1 if $start<1;
  my $end = $start+$maxshow;

  my $count = 0;
  foreach my $guid ( @$guests_L ) {
    my $g = $guests->{$guid};
    next unless $g->{ynm} eq $match;
    $count++;
    next unless $count >= $start && $count <= $end;
    my $link = lookup_guid_link($guid,$guests);
    print "<li> ";
    print "<a href=$ev->{THIS_URL}&delete=$guid>[remove]</a> "
      if $ev->{EDIT} && $MY_INVITE && $guid != $ev->{host};
    print "<b>$link</b>: \n";
    print "<i>(host)</i> " if $guid == $ev->{host};
    if ($g->{ynm} eq "Y" || $g->{ynm} eq "M") {
      print "(+ 1 guest) " if $g->{plus_guests} == 1;
      print "(+ $g->{plus_guests} guests) " if $g->{plus_guests} > 1;
    }
    if ($g->{ynm} eq "U" && $g->{reply_time}) {
      print "(viewed ";
      my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($g->{reply_time});
      my $ampm = $hour >= 12 ? "pm" : "am";
      $hour -= 12 if $hour > 12;
      $hour = $hour || 12;
      printf "%d/%d %d:%2.2d$ampm",$mon+1,$mday,$hour,$min;
      print ")";
    }
    print $g->{comments};
    print "<br>\n";
  }

  # Show the guest footer, i.e.:  "Showing 20-30 of 58, prev 20, next 20..."
  if ($start>1 || $total>$end) {
    print "<br><font size=-2>\n";
    print "Showing $start-$end of $total<br>\n";
    if ($start>1) {
      my $prev = $start-$maxshow;
      $prev = 1 if $prev<1;
      my $amt = $start-$prev;
      print "<a href=$ev->{THIS_URL}&start=$prev>prev $amt</a>";
      print ", " if ($total>$end);
    }
    if ($total>$end) {
      my $next = $maxshow;
      $next = $total-$end if $total-$end < $maxshow;
      my $at = $end+1;
      print "<a href=$ev->{THIS_URL}&start=$at>next $next</a>";
    }
    print "</font><br>\n";
  }
}

sub cmp_guests {
  my ($a,$b,$sort_name,$guests) = @_;
  return $guests->{$a}{NAME} cmp $guests->{$b}{NAME}
         || ($guests->{$a}{email} cmp $guests->{$b}{email})
    if ($sort_name);
  return ($guests->{$b}{reply_time} <=> $guests->{$a}{reply_time})
         || ($guests->{$a}{NAME} cmp $guests->{$b}{NAME})
         || ($guests->{$a}{email} cmp $guests->{$b}{email});
}

sub show_guests {
  my ($ev,$guests,$vars) = @_;

  return "" unless $guests;

#  return "&lt;&lt;GUEST REPLIES WILL GO HERE&gt;&gt;"
#    if ($vars->{EDIT});

  # Sort the guests first
  my $sort_name = $vars->{sort} eq "name" ? 1 : 0;
  # Get everyone's name in case we need to sort by name
  if ($sort_name) {
    foreach my $guid ( keys %$guests ) {
      $guests->{$guid}{NAME} = lookup_name($guid,$guests);
    }
  }
  my @guests = sort { cmp_guests($a,$b,$sort_name,$guests) } keys %$guests;

  # Then display them
  my $y = $vars->{y}; my $n = $vars->{n}; my $m = $vars->{m}; my $u = $vars->{u};

  if ($y) {
    print "<hr align=left width=90%><b>Yes:</b> [$y]<br><font size=-1><ul>\n";
    show_guests_match($ev,\@guests,$guests,"Y",$vars);
    print "</ul></font>\n";
  }
  if ($m) {
    print "<hr align=left width=90%><b>Maybe:</b> [$m]<br><font size=-1><ul>\n";
    show_guests_match($ev,\@guests,$guests,"M",$vars);
    print "</ul></font>\n";
  }
  if ($n) {
    print "<hr align=left width=90%><b>No:</b> [$n]<br><font size=-1><ul>\n";
    show_guests_match($ev,\@guests,$guests,"N",$vars);
    print "</ul></font>\n";
  }
  if ($u) {
    print "<hr align=left width=90%><b>Not yet replied:</b> [$u]<br><font size=-1><ul>\n";
    show_guests_match($ev,\@guests,$guests,"U",$vars);
    print "</ul></font>\n";
  }

  print "<hr align=left width=90%>\n";
  print "<font size=-2>sort responses:\n";
  print $sort_name ? "<a href=$ev->{THIS_URL}>date</a> | \n" : "date | \n";
  print $sort_name ? "name\n" : "<a href=$ev->{THIS_URL}&sort=name>name</a>\n";
  print "</font>\n";

  "";	# Theme subs print what they return..
}

sub handle_delete {
  my ($event,$guid,$delete) = @_;

  # Get guest info...
  my $ev = read_event($event);
  return ERROR("Unknown event [$event]??") unless $ev;

  header(0,$ev->{background});

  my ($y,$n,$m,$u,$guests) = read_guests($event);
  return ERROR("No guestlist for [$event]??") unless $guests;

  return ERROR("Guest [$delete] is not on the guestlist") unless $guests->{$delete};

  return ERROR("Only the host or the guest themselves can delete a guest")
    unless (($ev->{host} && $guid==$ev->{host}) || $guid==$delete);

  my $del_email = lookup_email($delete,$guests);
  my $del_name = lookup_name($delete,$guests);
  delete $guests->{$delete};

  write_guests($event,$guests);

  print "<h2>Guest $del_name [$del_email] has been deleted</h2>\n";
  return_link($event,$guid);
}

# Send me email listing all my invites
sub handle_get_invites {
  my ($email) = @_;

  my $name = get_name($email);

  header();

  # Check each event
  opendir(EVDIR,"$EVENTS") || return ERROR("Can't read event directory [$EVENTS]");
  my @events = grep(/^\d+$/, readdir(EVDIR));
  closedir(EVDIR);

  my @reply;
  my $guid;

  foreach my $event ( @events ) {
    my $ev = read_event($event);
    return ERROR("Unknown event [$event]??") unless $ev;
    my $title = $ev->{event_name_text} || "Untitled Event";

    my ($y,$n,$m,$u,$guests) = read_guests($event);
    return ERROR("No guestlist for [$event]??") unless $guests;

    # Are they on this guestlist?
    $guid=lookup_guid_by_email($email,$guests);
    push(@reply," $title:\n$URL?event=$event&guid=$guid\n\n") if $guid;
  }

  return ERROR("Sorry, that email isn't on any DaVite invites") unless @reply;

  my $mail_result = send_mail($email,"Your DaVite Invites",$email,$name,<<END_GET_INVITES);

Hi, $name!

Here are the URLs for the DaVites you are on:

 @reply

If you didn't request this email, please ignore this message and accept
our apologies.

If you receive multiple messages of this type, contact the domain owner
at the above URL.
END_GET_INVITES

  # Tell them it's created
  return ERROR("Couldn't send mail to $email:\n$mail_result") if $mail_result;
  header(0);
  print "<h2>Mail sent!</h2>\n";
  print "<h3>DaVite has sent you an email listing all your current DaVite URLs</h3>\n";
}

sub handle_reply {
  my ($event,$guid,$query) = @_;

  # Get guest info...
  my $ev = read_event($event);
  return ERROR("Unknown event [$event]??") unless $ev;

  header(0,$ev->{background});

  my ($y,$n,$m,$u,$guests) = read_guests($event);
  return ERROR("No guestlist for [$event]??") unless $guests;

  my $email = lookup_email($guid,$guests);
  my $name = lookup_name($guid,$guests);
  return ERROR("You aren't on the invite list!") unless $name;

  # Did they enter a new name?
  if (($query->{my_name} && $query->{my_name} ne $name) ||
      ($query->{hide_email} != hide_email($email))) {
    $name = $query->{my_name};
    set_name($email,$name,$query->{hide_email});
  }

  print "<br><br><center><font color=purple size=+1>Thanks $name for replying to $ev->{event_name}!</font></center><br>\n";

  # Update the guest hash and write it back
  $guests->{$guid}{ynm} = unhtml($query->{ynm});
  $guests->{$guid}{plus_guests} = unhtml($query->{plus_guests});
  if ($guests->{$guid}{plus_guests} < 0) {
    print "<br><i>Negative guests?  Nice try..  :-)</i><br>\n";
    $guests->{$guid}{plus_guests} = 0;
  }
  $guests->{$guid}{comments} = unhtml($query->{comments});
  $guests->{$guid}{reply_time} = time;
  write_guests($event,$guests);

  # Mail the host?
  if ($ev->{send_me_responses}) {
    my $host = $ev->{host};
    my $host_email = lookup_email($host,$guests);

    send_mail($host_email,"[DaVite] $ev->{event_name_text}",$email,$name,<<END_MAIL_RESPONSE);
$name has replied to your invitation "$ev->{event_name_text}"

Yes/No/Maybe:  $guests->{$guid}{ynm}
Guests:        $guests->{$guid}{plus_guests}
Comments:      $guests->{$guid}{comments}

For your invitation, visit DaVite at: [[KEEP THIS URL!]]
$URL?event=$event&guid=$host
END_MAIL_RESPONSE
  }

  return_link($event,$guid);
#  $MESSAGE = "Thanks for your reply!";
#  show_event($event,$guid);
}

sub reply_here {
  my ($ev,$guests,$vars) = @_;

  my $guid = $vars->{guid};
  unless ($guid) {
    return "" unless ($ev->{allow_invite_me});
    # Invite me?  (only if *not* on the invite - otherwise use "invite more")
    print <<INVITE_ME;
      <table><tr align=right><td>
        <form action=$URL method=POST name=handle_invite_me>
          <input type=text name=me size=20 maxlength=40 value='enter email here'>
          <br>
          <input type=submit name=handle_invite_me value='Invite me!'> 
          <input type=hidden name=event value=$ev->{ID}>
          <input type=hidden name=guid value=$guid>
        </form>
      </td></tr></table>
INVITE_ME
    return "";
  }

  # We don't want to interfere with the edit form
  return "<br>&lt;&lt;ATTENDANCE FORM WILL GO HERE&gt;&gt;<br>\n"
    if ($vars->{EDIT});

  my $check_hide;
  $check_hide = "checked" if (hide_email(lookup_email($guid,$guests)));

  my $name = $vars->{name};  $name =~ s/"/&quot;/g;
  print <<ATTEND;
  <table><tr><td>
  <form action=$URL method=POST name=reply_here>
    <table width=100%>
      <tr><td align=left>
        <input type=radio name=ynm value=Y $vars->{Ychecked}><b>Yes</b>
        <input type=radio name=ynm value=N $vars->{Nchecked}><b>No</b>
        <input type=radio name=ynm value=M $vars->{Mchecked}><b>Maybe</b>
      </td><td align=right>
        <input type=submit name=reply value="Reply">
      </td></tr>
    </table>
    <p>
    <b>Comments:</b>
    <br>
    <textarea name=comments rows=5 cols=30 wrap>$guests->{$guid}{comments}</textarea>
    <p>
    <table width=100%>
      <tr><td align=left>
    I am bringing
    <input type=text name=plus_guests size=2 value=$guests->{$guid}{plus_guests}>
    guests
      </td><td align=right>
        <input type=submit name=reply value="Reply">
      </td></tr>
    </table>
    <p>
    My name is
    <input type=text name=my_name size=20 value="$name">
    <br>
    Hide my email:
    <input type=checkbox name="hide_email" value="1" $check_hide>
    <input type=hidden name=event value=$ev->{ID}>
    <input type=hidden name=guid value=$guid>
  </form>
  </td></tr></table>
ATTEND

  "";	# Theme subs print what they return..
}

sub create_event {
  my ($email) = @_;

  chomp($email);

  # Do they have a real email address?
  unless ($email =~ /^\s*(\S+\@\S+\.\S+)\s*$/) {
    ERROR("Proper email [$email] address needed to create events");
    return empty_query();
  }
  $email = $1;

  # Can they?
  unless (grep($email =~ /$_/, @CAN_CREATE)) {
    ERROR("[$email] isn't allowed to create invites on this DaVite system");
    return empty_query();
  }

  # Come up with an event id
  my $event;
  while (1) {
    $event = int(rand(0xfff) | rand(0xff)<<12 | rand(0xfff)<<20);

    # Make sure someone else isn't using it
    last unless -d "$EVENTS/$event";
  }
  mkdir("$EVENTS/$event",0755) ||
    return ERROR("Couldn't create directory [$event]");

  my $guid = int(rand(0xfff) | rand(0xff)<<12 | rand(0xfff)<<20);

  my %ev; my $ev = \%ev;
  $ev->{ID} = $event;
  foreach (@KEYS,@MORE_KEYS) {
    $ev->{$_} = "";
  }
  $ev->{theme} = "Basic";
  if (!-f "$THEMES_DIR/$ev->{theme}" && opendir(T,$THEMES_DIR)) {
    # Pick first available theme
    my @t = grep(-f "$THEMES_DIR/$_", readdir(T));
    closedir T;
    $ev->{theme} = $t[0];
  }
  $ev->{host} = $guid;
  $ev->{allow_invites} = 1;
  $ev->{allow_invite_me} = 0;
  $ev->{send_me_responses} = 0;
  write_event($ev);
  my %guests;
  $guests{$guid}{email} = $email;
  write_guests($event,\%guests);

  # We used to take them directly to the event
  #show_event($event,$guid,1);
  # But then we have no email verification, so let's fix that..

  # Mail them the link to edit it.
  my $mail_result = send_mail($email,"New DaVite Invite",$email,$email,<<END_CREATE_MSG);

Hi, $email!

Here's the URL to the DaVite you just created:  [[KEEP THIS URL!]]
$URL?event=$event&guid=$guid&edit

If you didn't create this invite, please ignore this message and accept
our apologies.

If you receive multiple messages of this type, contact the domain owner
at the above URL.
END_CREATE_MSG

  # Tell them it's created
  return ERROR("Couldn't send mail to $email:\n$mail_result") if $mail_result;
  header(0);
  print "<h2>Your event has been created</h2>\n";
  print "<h3>You will be receiving an email with its URL shortly</h3>\n";
}

sub edit_event {
  my ($event,$guid,$query) = @_;

  my $ev = read_event($event);
  return unless $ev;

  header(0,$ev->{background});

  # Should we allow them to change host if they want to force it by spoofing
  # the form?  Sure, I can't see any harm in them giving up their own access.
  my $changes;
  foreach my $var ( @KEYS,@MORE_KEYS, keys %$ev ) {
    next unless defined $query->{$var};
    $query->{$var} =~ s///g;
    next if $query->{$var} eq $ev->{$var};
    #print STDERR "\nVAR $var: [$query->{$var}] vs [$ev->{$var}]\n";
    $changes++;
    $ev->{$var} = $query->{$var};
  }

  if ($changes) {
    write_event($ev);
    print "<br><br>\n";
    print "<h2>Changes saved in event details</h2>\n";
#    $MESSAGE = "Event changes saved";
  } else {
    print "<br><br>\n";
    print "<h2>No changes found<br>Event not modified</h2>\n";
#    $MESSAGE = "No changes to event";
  }

  return_link($event,$guid);
  print "<br><br>\n";
#  show_event($event,$guid);
}

sub button {
  my ($button,$url,$width,$height) = @_;
  print <<END_BUTTON;
<a href=$url
           onMouseOver = document.images['$button'].src='$PICS/$button.down.gif'
            onMouseOut = document.images['$button'].src='$PICS/$button.gif'
           onMouseDown = document.images['$button'].src='$PICS/$button.down.gif'
             onMouseUp = document.images['$button'].src='$PICS/$button.gif'>
<img name=$button width=$width height=$height border=0 src=$PICS/$button.gif></a>
END_BUTTON
}

sub toolbar {
  my ($ev,$guests,$vars) = @_;

  my $email = lookup_email($vars->{guid},$guests);
  button("Create_Invite","$URL?create=1&email=$email",69,19)
    if ($email && grep($email =~ /$_/, @CAN_CREATE));

  if ($MY_INVITE) {
    ($ev->{EDIT}) ?
      button("Preview_Event","$ev->{THIS_URL}",75,19) :
      button("Edit_Event","$ev->{THIS_URL}&edit",57,19);
    button("Mail_Guests","$ev->{THIS_URL}&mail",63,19);
  }
  "";	# Theme subs print what they return..
}

sub my_invite { my ($ev,$guid) = @_;  (!$ev->{host} || $guid == $ev->{host}) ? 1 : 0; }

sub show_event {
  my ($event,$guid,$edit,$query) = @_;

  # Vars that the theme can use
  my %vars;
  $vars{url} = $URL;
  $vars{event} = $event;
  $vars{guid} = $guid;
  $vars{THIS_URL} = "$URL?event=$event&guid=$guid";
  if ($query) {
    foreach ( qw(sort start maxshow) ) {
      $vars{$_} = $query->{$_};
    }
  }

  # Get event/guest info
  my $ev = read_event($event);
  return unless $ev;
  $ev->{THIS_URL} = $vars{THIS_URL};
  $vars{event_name} = $ev->{event_name};

  # Only the owner can edit the invite
  $MY_INVITE = my_invite($ev,$guid);
  $edit = 0 unless $MY_INVITE;
  $ev->{EDIT} = $edit;
  $vars{EDIT} = $edit;
  $vars{data} = $DAVITE_URL;

  my ($y,$n,$m,$u,$guests) = read_guests($event);
  $vars{y} = $y; $vars{n} = $n; $vars{m} = $m; $vars{u} = $u;

  # Lookup guid
  $vars{name} = lookup_name($guid,$guests);
  $vars{if_not} = $vars{name} ?
    "Click <a href=$URL?event=$event>here</a> if you are not $vars{name}" : "";
  $vars{greeting} = $guid ?
    $vars{name} ?
      "Hi, $vars{name}!" :
      "Unknown guest id, please check the URL that was mailed to you!" :
      "<font size=+1>Please use the full URL you were sent for this invite if you want to reply to it as a guest.</font>";

  # Is this there first viewing?
  if ($guid && $vars{name} && !$guests->{$guid}{reply_time}) {
    $guests->{$guid}{reply_time} = time;
    write_guests($event,$guests);
  }

  # Invite others?
  my $allow = $ev->{allow_invites};
  $allow = 1 if $MY_INVITE;
  $allow = 0 unless lookup_email($guid,$guests);
  $vars{invite_link} = ($allow) ?
    "<a href=$URL?event=$event&guid=$guid&invite>invite more people</a>" : "";

  if ($edit) {
    my $greet;
    $greet = "<form action=$URL method=POST name=edit_event>";
    $greet .= "$vars{greeting}";
    $greet .= "<input type=hidden name=event value=$ev->{ID}>";
    $greet .= "<input type=hidden name=guid value=$guid>";
    $vars{greeting} = $greet;
  }

#  if ($MESSAGE) {
#    $vars{greeting} .= "&nbsp;&nbsp;--&nbsp;&nbsp;<b>$MESSAGE<b>";
#  }


  # Do the theme
  show_theme($ev,$guests,\%vars);

  print "<input type=submit name=edit_event value='Save Changes'>\n</form>\n"
    if ($edit);
}

sub handle_mail_guests {
  my ($event,$guid,$query) = @_;

  return mail_guests($event,$guid,$query,"Please enter a message") unless $query->{message};
  return mail_guests($event,$guid,$query,"Please type in a subject") unless $query->{subject};

  my $ev = read_event($event);
  return ERROR("Unknown event [$event]??") unless $ev;
  my ($y,$n,$m,$u,$guests) = read_guests($event);

  $MY_INVITE = my_invite($ev,$guid);
  return ERROR("Nice try.  Only the invite owner can send mail.") unless $MY_INVITE;

  header(0,$ev->{background});

  my $from = lookup_email($guid,$guests);
  my $from_full = lookup_name($guid,$guests);

  print "<center>\n";
  print "<h2>Sent mail:</h2>\n";
  print "</center>\n";
  print "<table width=95%>\n";
  print "<tr><th width=40%> </th><td width=30%><b>Name</b></td><td width=30%><b>Email</b></td></tr>\n";
  print "<tr><td colspan=3><hr></td></tr>\n";

  # Make sure they didn't get confused by the AND and uncheck match_v/match_nv
  ($query->{match_v},$query->{match_nv}) = (1,1)
    if (!$query->{match_v} && !$query->{match_nv});

  foreach my $some_id ( keys %$guests ) {
    my $ynm = $guests->{$some_id}{ynm};
    my $viewed = $guests->{$some_id}{reply_time};
    next if ($ynm eq "Y" && !$query->{match_y});
    next if ($ynm eq "N" && !$query->{match_n});
    next if ($ynm eq "M" && !$query->{match_m});
    next if ($ynm eq "U" && !$query->{match_u});
    next if ($viewed     && !$query->{match_v});
    next if (!$viewed    && !$query->{match_nv});
    my $email = lookup_email($some_id,$guests);
    my $name = lookup_name($some_id,$guests);

    my $mail_result = send_mail($email,$query->{subject},$from,$from_full,<<END_REMINDER);
Hi $name!  Here's a DaVite reminder:

$query->{message}

For your invitation, visit DaVite at:  [[KEEP THIS URL!]]
$URL?event=$event&guid=$some_id
END_REMINDER

    $mail_result = $mail_result ? "<font color=red>$mail_result</font>" : "Mail sent!";
    print "<tr><td><b>$mail_result</b></td><td>$name</td><td>$email [$ynm]</td></tr>\n";
  }

  print "</table>\n";
  print "<br><br>\n";

  return_link($event,$guid,10);
#  $MESSAGE = "Mail sent to $sent guests!";
#  show_event($event,$guid);
}

sub mail_guests {
  my ($event,$guid,$query,$message) = @_;

  my $ev = read_event($event);
  return ERROR("Unknown event [$event]??") unless $ev;

  $MY_INVITE = my_invite($ev,$guid);
  return ERROR("Nice try.  Only the invite owner can send mail.") unless $MY_INVITE;

  header(0,$ev->{background});

  my $subject = $query->{subject};  $subject =~ s/"/&quot;/g;
  print "<center><font color=red><h2>$message</h2></font></center>" if $message;

  print <<MAIL;
<br>
<center>
<b>
<font size=+3>
$ev->{event_name}
</font>
</center>
<br>
<font size=+2>
Send mail to Guests who:
</font>
</b>
<br> <br>
</center>
<form action=$URL method=POST name=handle_mail>
  <table>
    <tr>
      <td width=50% align=left>
        <input type=checkbox name=match_y value=1 checked>are coming<br>
        <input type=checkbox name=match_m value=1 checked>may be coming<br>
      </td>
      <td align=left>
        <input type=checkbox name=match_n value=1 checked>aren't coming<br>
        <input type=checkbox name=match_u value=1 checked>haven't replied<br>
      </td>
    </tr><tr>
      <td colspan=2>
        <b>AND:</b>
      </td>
    </tr><tr>
      <td align=left>
        <input type=checkbox name=match_v value=1 checked>have viewed the invite<br>
      </td>
      <td align=left>
        <input type=checkbox name=match_nv value=1 checked>haven't viewed the invite<br>
      </td>
    </tr>
    <tr>
      <td colspan=2 align=left>
        <br>
        <b>Subject:</b> <input type=text name=subject size=60 maxlength=200 value="$subject">
        <p>
        <b>Message:</b><br>
        <textarea name=message rows=10 cols=75 wrap=0>$query->{message}</textarea>
      </td>
    </tr>
    <tr>
      <td colspan=2 align=right>
        <input type=submit name=handle_mail value="Send Mail">
      </td>
    </tr>
  </table>
  <input type=hidden name=event value=$ev->{ID}>
  <input type=hidden name=guid value=$guid>
</form>
MAIL

  print "<br>\n";
  return_link($event,$guid,-1);
  print "<br><br>\n";
}

sub invite_people {
  my ($event,$guid) = @_;

  my $ev = read_event($event);
  return ERROR("Unknown event [$event]??") unless $ev;

  header(0,$ev->{background});

  print <<INVITE_PEOPLE;
<br>
<center>
<b>
<font size=+2>
Invite People To:
</font>
<br>
<font size=+3>
$ev->{event_name}
</font>
</b>
<br> <br>
</center>
Enter a list of email addresses separated by commas or new lines.
<br>
You can put full names before email addresses, and we'll try to figure
the whole mess out.
<br>
<form action=$URL method=POST name=handle_invite>
  <textarea name=invitees rows=6 cols=60 wrap></textarea>
  <input type=hidden name=event value=$ev->{ID}>
  <input type=hidden name=guid value=$guid>
  <br>
  <input type=submit name=handle_invite value="Invite these fine folks">
  <p>
<i>
Example input:
<pre>
  somebody\@davite.com, someone_else\@davite.com
  Joe Wallatree joe\@joewallatree.com
  "Full Name" &lt;another_person\@davite.com&gt;
</pre>
</i>
  <p>
  You can also include an optional message in the invite email:<br>
  <textarea name=message rows=5 cols=60 wrap></textarea>
</form>
<br>

INVITE_PEOPLE

  print "<br>\n";
  return_link($event,$guid,-1);
  print "<br><br>\n";
}

# Since there is no login, all security is based upon the URL and
# the guid being private.  (Hey, the software is free, okay?)
# So we want to eventually make the guid non-calculatable, and
# a normal random stream is pretty easy to calculate given one guid.
# If need be we could encrypt the output of rand with another rand??
#
# For now we'll trust that multiple calls to srand() will give us
# sufficiently non-streamed values
sub new_guid {
  my ($guests) = @_;
  while (1) { # Make sure this exits!
    srand();	# Will use /dev/urandom if we have it!  :)
    my $new = int(rand(0xfff) | rand(0xff)<<12 | rand(0xfff)<<20);
    next unless $new;	# We could get 0, and that would confuse things..

    # Make sure someone else isn't using it
    return $new unless grep($new == $_, keys %$guests);
  }
}

# Send mail
# Returns 0 if no error, else error string
sub send_mail {
  my ($to,$subject,$from,$from_full,$msg) = @_;

#  # Some mailers (like exim) can't handle:  me@here.com <me@here.com>
#  $from_full =~ s/\@/-AT-/g;

  my $mail_header = <<END_MAIL_HEADER;
From: "$from_full" <$from>
Subject: $subject
To: $to
X-Mailer: $URL
END_MAIL_HEADER

  my $mail_sig = <<END_MAIL_SIG;
---------------------------------------------------------------------------
DaVite Invitation Software            http://MarginalHacks.com/Hacks/DaVite
This invitation was sent to you by $from_full using DaVite software.
If you can't click on the link above, copy it into your browser
END_MAIL_SIG

			unless ($USE_SENDMAIL_PM) {
  #########################
  # UNIX: Sendmail pipe
  #########################
  return ERROR("Can't open sendmail pipe!\n".
               "Try installing Sendmail.pm and set the \$USE_SENDMAIL_PM variable in DaVite.cgi\n")
    unless open(MAIL,"|$SENDMAIL -i -S $SMTP_SMARTHOST:$SMTP_PORT -f $from $to");
  print MAIL "$mail_header\n\n";
  print MAIL "$msg\n";
  print MAIL $mail_sig;
  close MAIL;

			} else {
  #########################
  # Windows:  Sendmail.pm
  #########################
  my %mail = ( To => $to, From => "$from_full <$from>",
               Subject => $subject, Message => "$msg\n$mail_sig" );
  Mail::Sendmail::sendmail(%mail) or return "Sendmail.pm error to: [$to]\n$Mail::Sendmail::error";

			}

  return 0;
}

# &chars;	(Don't try to edit this!)
my %AMP_CHARS=( 'amp'=> '&', 'lt'=> '<', 'gt'=> '>', 'nbsp'=> '', 'Iacute'=> 'Í', 'iacute'=> 'í',
	'Aacute'=> 'Á', 'aacute'=> 'á', 'Oacute'=> 'Ó', 'oacute'=> 'ó', 'Eacute'=> 'É',
	'eacute'=> 'é', 'Uacute'=> 'Ú', 'uacute'=> 'ú', 'Ntilde'=> 'Ñ', 'ntilde'=> 'ñ', 'uuml'=> 'ü',);
sub amp_chars { $AMP_CHARS{lc($_[0])} || "\&$_[0];"; }

# A poor attempt to strip HTML tags from a string
sub strip_html {
  my ($str) = @_;

  $str =~ s/<(br|p)[^>]*>/ - /g;	# Weak kludge

  # Plain tags
  my $tags=join('|', qw(h\d a p br hr html head b i center nobr ol ul));
  # Tags that take args
  my $arg_tags="a (href|name)=|".join('|', qw(title body font img table td tr p input form meta));

  $str =~ s#</?($tags|($arg_tags)[^>]*)>##mig;
  $str =~ s/\&([^;]+);/amp_chars($1)/emig;
  $str;
}

sub handle_invite_people {
  my ($event,$guid,$query) = @_;

  my $ev = read_event($event);
  return ERROR("Unknown event [$event]??") unless $ev;
  my ($y,$n,$m,$u,$guests) = read_guests($event);

  my $from = lookup_email($guid,$guests);
  return ERROR("You need to be logged into an invite to invite other people")
    unless $from;
  my $from_full = lookup_name($guid,$guests);

  return ERROR("Sneaky, but you're not allowed to do that unless you own the invite")
    unless $ev->{allow_invites} || my_invite($ev,$guid);

  my @guests = map($guests->{$_}{email}, keys %$guests);
  my @invite_list;
  my $added_guests = 0;
  my $new_names = 0;
  my $nick = read_names();

  header(0,$ev->{background});

  $ev->{notes_text} = strip_html($ev->{notes});

  my @invitees = split(/[\n,]/,$query->{invitees});
  print "<center>\n";
  print "<h2>Processed invitations:</h2>\n";
  print "</center>\n";
  print "<table width=95%>\n";
  print "<tr><th width=40%> </th><td width=30%><b>Name</b></td><td width=30%><b>Email</b></td></tr>\n";
  print "<tr><td colspan=3><hr></td></tr>\n";
  foreach my $email ( @invitees ) {
    # Comment?
    if ($email =~ /^#/) {
      print "<tr><td><b><font color=red>Ignored:</font></b></td><td colspan=2><b>commented line: [$email]</b></td></tr>\n";
      next;
    }

    # Parse the invites name/email
    next unless $email =~ /\S/;
    $email =~ s/^\s+//; $email =~ s/\s+$//;
    my $name;
    ($name,$email) = ($1,$2) if ($email =~ /^(.*\S)\s+(\S+\@\S+)$/);
    $name =~ s/^["'<]+//; $name =~ s/["'>]+$//;
    $email =~ s/^["'<]+//; $email =~ s/["'>]+$//;

    # Bad email?
    if ($email !~ /\@/) {
      print "<tr><td><b><font color=red>Error:</font></b></td><td colspan=2><b>Can't understand invitee: [$email]</b></td></tr>\n";
      next;
    }

    # Name?
    if ($nick->{$email}) {
      $name = $nick->{$email};
    } elsif ($name) {
      # We got a new name to save
      $new_names++;
      $nick->{$email} = $name;
    }

    # Are they already on the list?
    # We'll assume that email is case-insensitive.  Technically I suppose
    # the login part is not, but we'll see lots of repeated invites otherwise.
    if (grep(lc($email) eq lc($_), @guests)) {
      print "<tr><td><b><font color=red>Already invited:</font></b></td><td>$name</td><td>$email</td></tr>\n";
      next;
    }

    # Create the guest
    my $new = new_guid($guests);

    # Add them to the guestlist
    $guests->{$new}{email} = $email;
    push(@guests,$email);
    push(@invite_list,"  $name [$email]\n");
    $added_guests++;

    # Mail the invitation
    my $mail_result = send_mail($email,$ev->{event_name_text},$from,$from_full,<<END_INVITE);

Hi $name!

$from_full has invited you to "$ev->{event_name_text}".

For your invitation, visit DaVite at:  [[KEEP THIS URL!]]
$URL?event=$event&guid=$new

$query->{message}
-------------------------

$ev->{notes_text}
END_INVITE

    $mail_result = $mail_result ? "<font color=red>$mail_result</font>" : "Success";

    print "<tr><td><b>$mail_result</b></td><td>$name</td><td>$email</td></tr>\n";
  }
  write_names() if $new_names;
  write_guests($event,$guests) if $added_guests;

  print "</table>\n";
  print "<br>\n";

  # Mail the host?
  if ($guid != $ev->{host} && $added_guests && $ev->{send_me_responses}) {
    my $host = $ev->{host};
    my $host_email = lookup_email($host,$guests);

    send_mail($host_email,"[DaVite] $ev->{event_name_text}",$from,$from_full,<<END_TELL_HOST);

DaVite message from: $from_full [$from]:
I've invited new people to your invitation "$ev->{event_name_text}":
@invite_list

For your invitation, visit DaVite at:  [[KEEP THIS URL!]]
$URL?event=$event&guid=$host
END_TELL_HOST
  }

  return_link($event,$guid,10);
  print "<br><br>\n";
}


sub handle_invite_me {
  my ($event,$guid,$query) = @_;

  my $ev = read_event($event);
  return ERROR("Unknown event [$event]??") unless $ev;
  my ($y,$n,$m,$u,$guests) = read_guests($event);

  return ERROR("Sneaky, but you're not allowed to do that for this invite")
    unless $ev->{allow_invite_me};

  header(0,$ev->{background});

  $ev->{notes_text} = strip_html($ev->{notes});

  my $email = $query->{me};
  $email =~ s/^\s+//;
  $email =~ s/\s+$//;
  my $name = $email;

  return ERROR("You need to enter a valid <b>full</b> email address<br>(Not '$email')")
    unless ($email =~ /^\S+\@\S+\.\S+$/);

  # Name?
  my $name = get_name($email);

  # Are they already on the list?
  # We'll assume that email is case-insensitive.  Technically I suppose
  # the login part is not, but we'll see lots of repeated invites otherwise.
  my @guests = map($guests->{$_}{email}, keys %$guests);
  return ERROR("You are already invited.<br>See the invite host if you've forgotten your URL.")
    if (grep(lc($email) eq lc($_), @guests));

  # Create the guest
  my $new = new_guid($guests);

  # Add them to the guestlist
  $guests->{$new}{email} = $email;

  # Mail the invitation
  my $mail_result = send_mail($email,$ev->{event_name_text},$email,"DaVite Invitation System",<<END_INVITE);

Hi $name!

You have invited yourself to "$ev->{event_name_text}".

If this is a mistake, please ignore this message, or reply
to the host of the invitation at the following URL.

For your invitation, visit DaVite at:  [[KEEP THIS URL!]]
$URL?event=$event&guid=$new

$query->{message}
-------------------------

$ev->{notes_text}
END_INVITE

  return ERROR("Mailing error??\n$mail_result") if $mail_result;

  write_guests($event,$guests);

  print "<h2>Hi $name</h2>\n";
  print "<h3>You have been sent an invitation,\n";
  print "but you have <b>not</b> responded yet.</h3>\n";
  print "You can only respond using the URL that we just emailed to you,\n";
  print "so check your email and then visit the URL it gives you.<p></h2>\n";

  # Mail the host?
  my $host = $ev->{host};
  my $host_email = lookup_email($host,$guests);

  send_mail($host_email,"[DaVite] $ev->{event_name_text}",$email,$name,<<END_TELL_HOST);

$name [$email] has invited themselves to:
  "$ev->{event_name_text}"

For your invitation, visit DaVite at:  [[KEEP THIS URL!]]
$URL?event=$event&guid=$host
END_TELL_HOST

  return_link($event,undef,10);
  print "<br><br>\n";
}

##################################################
# Do it
##################################################
sub main {
  my $query = parse_query();

  my $event = $query->{event};
  my $guid = $query->{guid};
  my $edit = $query->{edit};

  if ($query->{create}) {
    create_event($query->{email});
  } elsif ($query->{delete}) {
    handle_delete($event,$guid,$query->{delete});
  } elsif ($query->{get_invites}) {
    handle_get_invites($query->{email});
  } elsif ($query->{mail}) {
    mail_guests($event,$guid);
  } elsif ($query->{handle_mail}) {
    handle_mail_guests($event,$guid,$query);
  } elsif ($query->{handle_invite}) {
    handle_invite_people($event,$guid,$query);
  } elsif ($query->{handle_invite_me}) {
    handle_invite_me($event,$guid,$query);
  } elsif ($query->{invite}) {
    invite_people($event,$guid);
  } elsif ($query->{reply}) {
    handle_reply($event,$guid,$query);
  } elsif ($query->{edit_event}) {
    edit_event($event,$guid,$query);
  } elsif ($query->{event}) {
    show_event($event,$guid,$edit,$query);
  } elsif (keys %$query) {
    ERROR("Unknown request");
    print "<ul>\n";
    foreach ( keys %$query ) {
      print "<li> $_ $query->{$_}\n";
    }
    print "</ul>\n";
  } else {
    empty_query();
  }

  footer();	# If we need did the default header
} main();
