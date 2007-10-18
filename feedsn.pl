#!/usr/pkg/bin/perl
#
# feedsn.pl
#
# Rick Umali (rickumali@gmail.com)
#
# V1.0 - 10/13/2007
# Initial revision.
#
#
use strict;

use Getopt::Long;
use WWW::Mechanize;
use HTML::TokeParser;
use XML::Writer;
use IO::File;
use XML::RSS;
use POSIX;

my $version = 0.5;
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

while (my $div_tag = $stream->get_tag("div")) {

	if ($div_tag->[1]{class} && $div_tag->[1]{class} eq "MBEntry") {
		my $id = $div_tag->[1]{id};

		$subject{$id} = get_subject($stream);
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
    $rss->add_item(title => $subject{$id},
                   link  => "http://www.sportingnews.com/blog/rickumali/$display_id",
                   permaLink  =>
"http://www.sportingnews.com/blog/rickumali/$display_id",
                   description => substr($text{$id},0,160) . "..."
                  );
}

$rss->save($feedname);
print "Generated $feedname with pubDate: $pubDate\n";

exit 0;

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
