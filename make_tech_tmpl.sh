#!/bin/sh
#
# make_tech_tmpl.sh
#
# This SH script builds tech.tmpl
#
# Rick Umali / 2013-01-05

# First, get the feed
curl -O https://tech.rickumali.com/rss.xml

if [ -s rss.xml ] ; then
	# If the feed exists, then rename it to a good temp file
	mv rss.xml feed-TechTalk-$$.xml

	# Run processfeed.pl to produce a tech.tmpl file
	/usr/bin/perl process_tech_feed.pl feed-TechTalk-$$.xml > tech.tmpl

	# Delete the feed
	rm -f feed-TechTalk-$$.xml
else
	echo "No Rick on Tech Feed!" > msg.$$
	cat msg.$$

	rm -f msg.$$
fi
