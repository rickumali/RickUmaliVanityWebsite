#!perl
#
# process_sports_feed.pl
#
# Reads an XML file containing Rick on Sports "feed" from FeedBurner. The
# feed is in RSS. This program dumps to STDOUT. The program reads the
# template file sports_start.tmpl
#
# Usage:
#
# perl process_sports_feed.pl feed-RickOnSports.xml > sports.tmpl
#
# 2007-12-01 - Original
#
# 2007-12-05 - Modified code to handle pretty-printing of date
#
# 2007-12-07 - Modified code to use Template Toolkit
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
my $channel_hash;

# Walk through each "element" of the RSS feed. When you see the "entry" element,
# save it away in a hash ref
$key_count = 0;
foreach my $elem (keys %{$rss_feed}) {
	$key_count++;

	if ($elem eq "channel") {
		$channel_hash = %{$rss_feed}->{$elem};
	}
}

# The "channel" hash ref contains an item array. Walk through
# each "item", and build a structure that will hold the template's
# variables.
my @entry_array = ();
$key_count = 0;
my @item_array = @{$channel_hash->{item}};
foreach my $item (@item_array) {
	print "$key_count: $item\n" if $opt_debug;

	my $published_date = get_published_date($item);
	my $title = get_title($item);
	my $link = get_url_link($item);
	my $text = get_text($item);

	# This builds an array of anonymous HASHes containing the data
	# that will be shown in the template
	push @entry_array, { 
		published_date => $published_date,
		title => $title, 
		url => $link, 
		text => $text, 
	};

	$key_count++;
}

my $vars = {
	current_time_stamp => localtime() . "",
	entries => \@entry_array,
};
my $tt = Template->new({
	INTERPOLATE => 1,
#	POST_CHOMP => 1,
}) || die "$Template::ERROR\n";

$tt->process('sports_start.tmpl', $vars)
	|| die $tt->error(), "\n";

sub get_published_date () {
	my $entry = shift;
	print "\tPublished: " . $entry->{"pubDate"} . "\n" if $opt_debug;

	# The feed contains a timestamp formatted like this:
	#
	# POSIX::strftime( "%a, %d %b %Y %H:%M:00 EDT"
	# Tue, 27 Nov 2007 22:08:00 EDT

	# Break apart the timestamp, and reformat it
	my ($unused, $day, $month, $year, $time, $zone) = split(' ', $entry->{"pubDate"});

	# The month_full HASH translates from the abbreviation to the full
	# month name
	my %month_full = (
		Jan => "January",
		Feb => "February",
		Mar => "March",
		Apr => "April",
		May => "May",
		Jun => "June",
		Jul => "July",
		Aug => "August",
		Sep => "September",
		Oct => "October",
		Nov => "November",
		Dec => "December",
	);

	$day =~ s/^0//; # Strip out any leading zeros
	return($month_full{$month} . " $day, $year");
}

sub get_url_link () {
	my $entry = shift;
	print "\tLink: " . $entry->{"link"} . "\n" if $opt_debug;
	return($entry->{"link"});
}

sub get_title () {
	my $entry = shift;
	print "\tTitle: " . $entry->{"title"} . "\n" if $opt_debug;
	return($entry->{"title"});
}

sub get_text() {
	my $entry = shift;

	print "\tText: " . $entry->{"description"} . "\n" if $opt_debug;
	return($entry->{"description"});
}
