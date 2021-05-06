#!/bin/sh
#
# make_flickr_tmpl.sh
#
# This SH script builds pictures.tmpl
#
# Rick Umali / 2007-12-02

# First, get the RickOnSports feed, via wget
wget -O feed.xml http://www.flickr.com/services/feeds/photos_public.gne\?id=69224449@N00\&lang=en-us\&format=rss_200

if [ -s feed.xml ] ; then
	# If the feed exists, then rename it to a good temp file
	mv feed.xml feed-flickr-$$.xml

	# Run processfeed.pl to produce a sports.tmpl file
	/usr/bin/perl process_flickr_feed.pl feed-flickr-$$.xml > pictures.tmpl

	# Delete the feed
	rm -f feed-flickr-$$.xml
else
	echo "No Rick Flickr Feed!" > msg.$$
	mail -s "Rick Index - No Feed for Rick's Flickr" rickumali@gmail.com < msg.$$

	rm -f msg.$$
fi

