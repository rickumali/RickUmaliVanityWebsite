#!/bin/sh
#
# make_sports_tmpl.sh
#
# This SH script builds sports.tmpl
#
# Rick Umali / 2007-12-02

# First, get the RickOnSports feed, via getfeed.pl
/usr/bin/perl getfeed.pl http://feeds.feedburner.com/RickOnSports

if [ -s feed.xml ] ; then
	# If the feed exists, then rename it to a good temp file
	mv feed.xml feed-RickOnSports-$$.xml

	# Run processfeed.pl to produce a sports.tmpl file
	/usr/bin/perl process_sports_feed.pl feed-RickOnSports-$$.xml > sports.tmpl

	# Delete the feed
	rm -f feed-RickOnSports-$$.xml
else
	echo "No Rick on Sports Feed!" > msg.$$
	mail -s "Rick Index - No Feed for RickOnSports" rickumali@gmail.com < msg.$$

	rm -f msg.$$
fi
