#!/usr/bin/perl
#
# processfeed.pl
#
# Reads an XML file containing the Rick's Ramblings "feed" from FeedBurner. The
# feed is in ATOM. This program dumps to STDOUT. This program reads the 
# template file blog_start.tmpl
#
# Usage:
#
# perl processfeed.pl feed-RickRamblings.xml > blog.tmpl
#
# 2007-11-25 - Original
#
# 2007-12-02 - Modified code to generate blog.tmpl
#
# 2007-12-05 - Modified code to handle pretty-printing of date
# 
# 2007-12-07 - Modified code to use Template Toolkit
#
# 2008-10-18 - Added bailout code in while() loop of get_truncated_text()
use strict;

use XML::Simple;
use Data::Dumper;
use Getopt::Long;
use HTML::TokeParser;
use Template;

my $opt_debug = 0;
my $opt_dump = 0;

GetOptions (
	'debug' => \$opt_debug,
	'dump' => \$opt_dump,
	); 

if (scalar(@ARGV) != 1) {
	exit 1;
}

my $feed_xml_file = $ARGV[0];

my $rss_feed = XMLin($feed_xml_file);

print STDERR Dumper($rss_feed) if $opt_dump;

my $key_count = 0;
my $entry_hash;

# Walk through each "element" of the RSS feed. When you see the "entry" element,
# save it away in a hash ref
$key_count = 0;
foreach my $elem (keys %{$rss_feed}) {
	$key_count++;

	if ($elem eq "entry") {
		$entry_hash = $rss_feed->{$elem};
	}
}

# Walk through each "entry", and build a structure that will hold 
# the template variables.
my @entry_array = ();
$key_count = 0;
foreach my $elem (sort bypubdate keys %{$entry_hash}) {
	my $entry = $entry_hash->{$elem};

	my $published_date = get_published_date($entry);
	my $title = get_title($entry);
	my $link = get_url_link($entry);
	my $text = get_truncated_text($entry, 160);

	# This builds an array of anonymous HASHes containing the data
	# that will be shown in the template
	push @entry_array, { 
		published_date => $published_date,
		title => $title, 
		url => $link, 
		text => $text, 
	};

	$key_count++;
	last if $key_count > 8; # Show the most recent eight entries
}

my $vars = {
	current_time_stamp => localtime() . "",
	entries => \@entry_array,
};
my $tt = Template->new({
	INTERPOLATE => 1,
#	POST_CHOMP => 1,
}) || die "$Template::ERROR\n";

$tt->process('blog_start.tmpl', $vars)
	|| die $tt->error(), "\n";

# bypubdate
#
# Used by the sort function, to reverse order the blog entries
sub bypubdate () {
	$entry_hash->{$b}->{published} cmp $entry_hash->{$a}->{published};
}

sub get_published_date () {
	my $entry = shift;
	my $orig_date = $entry->{"published"};
	print "\tPUBLISHED: $entry->{published}\n" if $opt_debug;	

	# The date is in this format
	#
	# 2007-11-29T22:18:00.001-05:00 

	$orig_date =~ m/(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):\d\d\..*/;
	my $year = $1;
	my $month = $2;
	my $day = $3;
	my $hour = $4;
	my $min = $5;

	# The month_full HASH translates from the numeric date to the full
	# month name
	my %month_full = (
		"01" => "January",
		"02" => "February",
		"03" => "March",
		"04" => "April",
		"05" => "May",
		"06" => "June",
		"07" => "July",
		"08" => "August",
		"09" => "September",
		"10" => "October",
		"11" => "November",
		"12" => "December",
	);

	$day =~ s/^0//; # Strip out any leading zeros

	my $reformatted_date = "$month_full{$month} $day, $year";
	print $reformatted_date if $opt_debug;
	return ($reformatted_date);
}

sub get_url_link () {
	my $entry = shift;
	my $links_count = scalar(@{$entry->{"link"}});
	foreach my $link (@{$entry->{"link"}}) {
		if ($link->{rel} eq "alternate") {
			print "\tLINK: $link->{href}\n" if $opt_debug;
			return($link->{href});
			# We unceremoniously drop out of this code, but 
			# it's fine.
		}
	}
}

sub get_title () {
	my $entry = shift;
	my $links_count = scalar(@{$entry->{"link"}});
	foreach my $link (@{$entry->{"link"}}) {
		if ($link->{rel} eq "alternate") {
			print "\tTITLE: $link->{title}\n" if $opt_debug;	
			return($link->{title});

			# We unceremoniously drop out of this code, but 
			# it's fine. I may need to do cleanup on this title
			# string if necessary.
		}
	}
}

sub get_truncated_text() {
	my $entry = shift;
	my $min_chars = shift;

	my $text_stream = HTML::TokeParser->new(\$entry->{content}->{content});
	my $text = $text_stream->get_phrase();

	if (length($text) < $min_chars) {
		print "\tTEXT: $text\n" if $opt_debug;
		return($text);
	} else {

		my $pos = 0;
		while ($pos < $min_chars) {
			$pos = index($text, " ", $pos+1);
			if ($pos == -1)	{
				# Bail out if index() returns -1. This means
				# that no spaces exist before $min_chars. This 
				# bail out code was added because of a boundary 
				# condition that caused this while() loop to 
				# run infinitely the week of 10/13/2008. NetAtlantic
				# shutdown rickumali.com because of this. See
				# Notebook files 20081017 and 20081018
				last;
			}
		}

		print "\tTEXT: " . substr($text,0,$pos) . " ..." . "\n"  if $opt_debug;
		return(substr($text,0,$pos) . "...");
	}
}
