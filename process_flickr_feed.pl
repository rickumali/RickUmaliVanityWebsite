#!perl
#
# process_flickr_feed.pl
#
# Reads an XML file containing the Rick's Flickr "feed" from Flickr. The
# feed is in RSS. This program dumps to STDOUT. This program reads the 
# template file pictures_start.tmpl
#
# Usage:
#
# perl process_flickr_feed.pl feed-flickr.xml > pictures.tmpl
#
# 2007-12-06 - Original
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
		$channel_hash = $rss_feed->{$elem};
	}
}

# The "channel" hash ref contains an item array
my @entry_array = ();
$key_count = 0;
my @item_array = @{$channel_hash->{item}};
foreach my $item (@item_array) {
	print "$key_count: $item\n" if $opt_debug;

	my $published_date = get_published_date($item);
	my $title = get_title($item);
	my $link = get_url_link($item);
	my $img_url = get_image_url($item);

	# This builds an array of anonymous HASHes containing the data
	# that will be shown in the template
	push @entry_array, { 
		published_date => $published_date,
		title => $title, 
		url => $link, 
		img_url => $img_url, 
	};

	$key_count++;
	last if $key_count > 8; # Show the most recent eight pictures
}

my $vars = {
	current_time_stamp => localtime() . "",
	entries => \@entry_array,
};
my $tt = Template->new({
	INTERPOLATE => 1,
}) || die "$Template::ERROR\n";

$tt->process('pictures_start.tmpl', $vars)
	|| die $tt->error(), "\n";

sub get_published_date () {
	my $entry = shift;
	print "\tPublished: " . $entry->{"pubDate"} . "\n" if $opt_debug;

	# The feed contains a timestamp formatted like this:
	#
	# Sat, 25 Aug 2007 18:39:40 -0800

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

# get_image_url
# 
# This tries to grab the IMG URL from a description that looks like this:
#
# <p><a href="http://www.flickr.com/people/rickumali/">rickumali</a>
# posted a photo:</p>
# <p><a href="http://www.flickr.com/photos/rickumali/1236257444/" title="Overpassin Seattle"><img src="http://farm2.static.flickr.com/1361/1236257444_1ffe2a6618_m.jpg" width="240" height="180" alt="Overpass in Seattle" /></a></p>
# <p>On the way to dinner, driving on Southcenter Boulevard, near Tukwila.
# There were plenty of these overpasses.</p>
# 
sub get_image_url() {
	my $entry = shift;

	my $text_stream = HTML::TokeParser->new(\$entry->{description});
	my $img_tag = $text_stream->get_tag("img"); 

	# This is a big help to figure out the structure
	print Dumper($img_tag) if $opt_debug;
	print "SRC: " . $img_tag->[1]->{"src"} if $opt_debug;

	return($img_tag->[1]->{"src"});
}
