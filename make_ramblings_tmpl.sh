#!/bin/sh
#
# make_ramblings_tmpl.sh
#
# This SH script builds blog.tmpl
#
# Rick Umali / 2007-12-02

# First, get the feed, via getfeed.pl
/usr/bin/perl getfeed.pl http://feeds.feedburner.com/RicksRamblings

if [ -s feed.xml ] ; then
	# If the feed exists, then rename it to a good temp file
	mv feed.xml feed-RicksRamblings-$$.xml

	# Run processfeed.pl to produce a blog.tmpl file
	/usr/bin/perl processfeed.pl feed-RicksRamblings-$$.xml > blog.tmpl
	rm -f feed-RicksRamblings-$$.xml
else
	echo "No RicksRamblings Feed!" > msg.$$
	mail -s "Rick Index - No Feed for Ricks Ramblings" rickumali@gmail.com < msg.$$

	rm -f msg.$$
fi
