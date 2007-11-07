#!/usr/pkg/bin/perl
#
# feedsn.pl
#
# Rick Umali (rickumali@gmail.com)
#
# V1.0 - 10/13/2007
#        Initial revision.
# V2.0 - 10/18/2007
#        Added support for dates.
# V3.0 - 11/04/2007
#        Finally fixed truncation
# V4.0 - 11/07/2007
#        Stopped writing to STDOUT
#
#
#
use strict;

use Date::Calc qw(Parse_Date Day_of_Week Day_of_Week_to_Text);
use Getopt::Long;
use WWW::Mechanize;
use HTML::TokeParser;
use XML::Writer;
use IO::File;
use XML::RSS;
use POSIX;

my $version = 4.0;
my $opt_debug = 0;
my $opt_version = 0;

GetOptions ('debug' => \$opt_debug,
            'version|v' => \$opt_version);

if ($opt_version) {
	print "feedsn.pl Version $opt_version\n";
	exit 1;
}

if ($opt_debug) {
	exit 1;
}

my $agent = WWW::Mechanize->new();
$agent->get("http://www.sportingnews.com/blog/rickumali");

my $stream = HTML::TokeParser->new(\$agent->{content});
my %subject = ();
my %text = ();
my %pubDate = ();

while (my $div_tag = $stream->get_tag("div")) {

	if ($div_tag->[1]{class} && $div_tag->[1]{class} eq "MBEntry") {
		my $id = $div_tag->[1]{id};

		$subject{$id} = get_subject($stream);
		$pubDate{$id} = get_pubdate($stream);
		$text{$id} = get_entry($stream);
	}
}

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
	gmtime(time);

my $feedname="rickonsports.rss";
my $pubDate = POSIX::strftime( "%a, %d %b %Y %H:%M:00 GMT", $sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);

my $rss = new XML::RSS (version => '2.0');
$rss->channel(title          => 'Rick on Sports',
              link           => 'http://www.sportingnews.com/blog/rickumali',
              language       => 'en',
              description    => 'Rick Umali\'s Take on Sports',
              copyright      => 'Copyright 2007, rickumali.com',
              pubDate        => $pubDate,
              lastBuildDate  => $pubDate,
              docs           => 'http://feedvalidator.org/docs/rss2.html',
              managingEditor => 'rickumali@gmail.com',
              webMaster      => 'rickumali@gmail.com'
             );

$rss->image(title       => 'Rick on Sports',
            url         => 'http://www.rodrigoumali.com/rick05.jpg',
            link           => 'http://www.sportingnews.com/blog/rickumali',
            width       => 144,
            height      => 130,
            description => 'Rick Umali'
           );

foreach my $id (sort {$b cmp $a} keys %subject) {
    my $display_id = $id;
    $display_id =~ s/entry_//;
    my $truncated_text = truncate_text($text{$id},160);
    $rss->add_item(title => $subject{$id},
                   link  => "http://www.sportingnews.com/blog/rickumali/$display_id",
                   pubDate  => $pubDate{$id},
                   permaLink  =>
"http://www.sportingnews.com/blog/rickumali/$display_id",
                   description => $truncated_text,
                  );
}

$rss->save($feedname);
# print "Generated $feedname with pubDate: $pubDate\n";

exit 0;

sub truncate_text() {
	my $text = shift;
	my $min_chars = shift; # Minimum number of characters for text

	if (length($text) < $min_chars) {
		return($text);
	}

	my $pos = 0;
	while ($pos < $min_chars) {
		$pos = index($text, " ", $pos+1);
	}

	return(substr($text,0,$pos) . " ...");

}

sub get_subject() {
	my $stream = shift;
	my $subject = "No Subject";
	while (my $div_tag = $stream->get_tag("div")) {

		if ($div_tag->[1]{id} && $div_tag->[1]{id} eq "MBSubject") {
			$stream->get_tag("a");
			$stream->get_token();
			$subject = $stream->get_trimmed_text();
			return($subject);
		}
	}
	return ($subject);
}

sub get_entry() {
	my $stream = shift;
	my $entry = "No Entry";
	while (my $div_tag = $stream->get_tag("div")) {

		if ($div_tag->[1]{id} && $div_tag->[1]{id} eq "MBBody") {
			$entry = $stream->get_phrase();
			return($entry);
		}
	}
	return ($entry);
}

sub get_pubdate() {
	my $stream = shift;
	my $pub_date_raw = "No Entry";
	my $pub_date = "No Entry";
	while (my $div_tag = $stream->get_tag("div")) {

		if ($div_tag->[1]{id} && $div_tag->[1]{id} eq "MBSubLine") {
			$stream->get_tag("em");
			$pub_date_raw = $stream->get_trimmed_text();
			$pub_date = reformat_date($pub_date_raw);
			return($pub_date);
		}
	}
	return ($pub_date_raw);
}

sub reformat_date() {
	my $pub_date_raw = shift;
	# Read this format: # >Oct 06, 2007 07:47 PM
	my ($raw_mon, $raw_day, $raw_year, $raw_time, $raw_merid) = split(' ', $pub_date_raw);
	chop($raw_day);
	my ($year, $month, $day) = Parse_Date($pub_date_raw);
	my $dow = Day_of_Week($year, $month, $day);
	my $today = Day_of_Week_to_Text($dow);
	if ($raw_merid eq "PM") {
		my ($hour,$min) = split(":", $raw_time);
		$hour+=12;
		if ($hour == 24) {
			$hour = 12;
		}
		$raw_time=sprintf("%02s:%02s",$hour,$min);
	}
	
	# Generate this format: Sat, 07 Sep 2002 9:42:31 GMT
	return(sprintf("%.3s, %s %s %s %s:00 EDT", 
		$today,$raw_day,$raw_mon,$year,$raw_time));
}
