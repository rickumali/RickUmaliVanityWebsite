#!/usr/bin/env perl
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
# V5.0 - 10/18/2008
#        Added bailout code to whileloop (search "bailout")
# V6.0 - 05/09/2021
#        Revamped retrieval of SportsBlog articles
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
use JSON::XS;

my $version = 6.0;
my $opt_debug = 0;
my $opt_version = 0;

GetOptions ('debug' => \$opt_debug,
            'version|v' => \$opt_version);

if ($opt_version) {
  print "feedsn.pl Version $opt_version\n";
  exit 1;
}

my $agent = WWW::Mechanize->new();
$agent->get("http://www.sportsblog.com/rickumali");

my $stream = HTML::TokeParser->new(\$agent->{content});
my %link = ();
my %subject = ();
my %text = ();
my %pubDate = ();
my $id_counter = 0;

while (my $article_tag = $stream->get_tag("h3")) {
  $id_counter += 1;
  print "Found <article> " . $id_counter . "\n" if $opt_debug;
  ($subject{$id_counter}, $link{$id_counter}) = get_subject_and_link($stream);
  print "  Found subject: " . $subject{$id_counter} . "\n" if $opt_debug;
  print "  Found link " . $link{$id_counter} . "\n" if $opt_debug;
}

my $article_count = $id_counter;
for (my $i = 1; $i <= $article_count; $i++) {
  print "Walking: " . $link{$i} . "\n" if $opt_debug;
  $agent->get($link{$i});
  my $stream = HTML::TokeParser->new(\$agent->{content});
  $stream->empty_element_tags(1);
  while (my $article_tag = $stream->get_tag("article")) {
    $pubDate{$i} = get_pubdate($stream);
    print "  pubDate: " . $pubDate{$i} . "\n" if $opt_debug;
    $text{$i} = get_entry($stream);
  }
}

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
  gmtime(time);

my $feedname="rickonsports.rss";
my $rssDate = POSIX::strftime( "%a, %d %b %Y %H:%M:00 GMT", $sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);

my $rss = new XML::RSS (version => '2.0');
$rss->channel(title          => 'Rick Umali: Sports On My Mind',
              link           => 'https://www.sportsblog.com/rickumali/',
              language       => 'en',
              description    => 'Rick Umali\'s Take on Sports',
              copyright      => 'Copyright 2007, rickumali.com',
              pubDate        => $rssDate,
              lastBuildDate  => $rssDate,
              docs           => 'http://feedvalidator.org/docs/rss2.html',
              managingEditor => 'rickumali@gmail.com',
              webMaster      => 'rickumali@gmail.com'
             );

$rss->image(title       => 'Rick Umali: Sports On My Mind',
            url         => 'http://www.rodrigoumali.com/rick05.jpg',
            link        => 'https://www.sportsblog.com/rickumali/',
            width       => 144,
            height      => 130,
            description => 'Rick Umali'
           );

for (my $id = 1; $id <= $article_count; $id++) {
    my $truncated_text = truncate_text($text{$id},160);
    $rss->add_item(title => $subject{$id},
                   link  => $link{$id},
                   pubDate  => $pubDate{$id},
                   permaLink  => $link{$id},
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
    if ($pos == -1) {
      # This bailout code was added following an
      # outage I caused on rickumali.com. There are
      # some instances of this while() loop going into
      # an infinite loop. This bailout code catches
      # that. (10-19-2008)
      last;
    }
  }
  return(substr($text,0,$pos) . " ...");
}

sub get_subject_and_link() {
  my $stream = shift;
  my $subject = "No Subject";
  my $link = "No Link";
  while (my $anchor_tag = $stream->get_tag("a")) {
    my $attr_hash_ref = $anchor_tag->[1];
    $subject = $stream->get_trimmed_text();
    return($subject, "http://www.sportsblog.com" . $attr_hash_ref->{href});
  }
  return ($subject, $link);
}

sub get_entry() {
  my $stream = shift;
  my $entry = "";
  my $keep_going = 1;
  while ($keep_going) {
    my $t = $stream->get_tag("p", "div");
    if ($t->[0] eq "div" and $t->[1]{class} eq "article-col") {
      $keep_going = 0;
    } elsif ($t->[0] eq "div" and $t->[1]{id} eq "article-content") {
      print "  article-content: " . $t->[1]{'data-article-content'} . "\n" if $opt_debug;
      my $raw_json = $t->[1]{'data-article-content'};
      my $json_decoded = decode_json $raw_json;
      print "  json_decoded: " . $json_decoded . "\n" if $opt_debug;
      print "  json_decoded->[0]: " . $json_decoded->[0] . "\n" if $opt_debug;
      for (keys %{$json_decoded->[0]}) {
        print("    $_ => $json_decoded->[0]{$_}\n") if $opt_debug;
      }
      my $children = $json_decoded->[0]{children};
      print "    children->[0]{text}: " . $children->[0]{text} . "\n" if $opt_debug;
      $entry .= $children->[0]{text};
    } else {
      $entry .= $stream->get_phrase();
      $entry .= " ";
    }
  }
  return ($entry);
}

sub get_pubdate() {
  my $stream = shift;
  my $pub_date_raw = "No Entry";
  my $pub_date = "No Entry";
  $stream->get_tag("p"); # articles-author-name
  $stream->get_tag("p"); # articles-author-blog-name
  $stream->get_tag("p"); # articles-author-date
  $pub_date_raw = $stream->get_phrase();
  $pub_date = reformat_date($pub_date_raw);
  return($pub_date);
}

sub reformat_date() {
  # Read this raw date: Feb. 06, 2021
  my $pub_date_raw = shift;
  print "  pub_date_raw: " . $pub_date_raw if $opt_debug;
  my ($raw_mon, $raw_day, $raw_year) = split(' ', $pub_date_raw);
  chop($raw_mon); # Remove trailing period
  chop($raw_day); # Remove trailing comma
  my $raw_time = "7:00"; # Hardcoded
  my $raw_merid = "PM"; # Hardcoded
  my $new_raw = $raw_mon . " " . $raw_day . " " . $raw_year;
  my ($year, $month, $day) = Parse_Date($new_raw);
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
