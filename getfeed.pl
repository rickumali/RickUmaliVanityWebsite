#!perl
#
# getfeed.pl
#
# Reads a feed, and grabs the title and item. 
#
# Rick Umali
#
# http://feeds.feedburner.com/RicksRamblings
# http://feeds.feedburner.com/RickOnSports
# http://api.flickr.com/services/feeds/photos_public.gne?id=69224449@N00&lang=en-us&format=rss_200
#
# To use this program, pass in one URL, either one of the above feed URLs
#
# perl getfeed.pl http://feeds.feedburner.com/RicksRamblings
#
# The program writes the contents of the feed to a file called feed.xml
# It'll be up to the calling program to rename the feed.xml
#
# 2007-11-24
use strict;

use LWP;

if (scalar(@ARGV) != 1) {
	exit 1;
}

my $feed_url = $ARGV[0];

my $browser = LWP::UserAgent->new;
my $resp = $browser->get($feed_url);

if ($resp->is_success) {
	open(OUT_XML, ">feed.xml") or die "Can't open feed.xml";
	print OUT_XML $resp->content;
	close(OUT_XML);
	exit 0;
} else {
	exit 1;
}
