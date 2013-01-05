rickumali-index

This is the software that generates the rickumali.com site.

The best way to read this code is to start "from the cron jobs":

min hr day month weekday    job
0   10   *     *       *    ./make_sports_tmpl.sh
10  10   *     *       *    ./make_ramblings_tmpl.sh
20  10   *     *       *    ./make_flickr_tmpl.sh
30  10   *     *       *    ./make_rick_index.sh

--------------------------------------------------------------------------------

A high-level view of which Perl scripts (.pl) get called, and what templates
(.tmpl) are used / generated:

make_sports_tmpl.sh -> getfeed.pl -> process_sports_feed.pl = sports.tmpl

make_ramblings_tmpl.sh -> getfeed.pl -> processfeed.pl = blog.tmpl

make_flickr_tmpl.sh -> getfeed.pl -> process_flickr_feed.pl = pictures.tmpl

make_rick_index.sh -> make_new_index.pl ->
    bio.tmpl + blog.tmpl + sports.tmpl + pictures.tmpl +
    contact.tmpl + footer.tmpl + rick-yui.tmpl = test.html = index.html

--------------------------------------------------------------------------------

References

http://www.template-toolkit.org/
http://developer.yahoo.com/yui
http://search.cpan.org/~gaas/libwww-perl-5.800/lib/LWP.pm
http://search.cpan.org/dist/HTML-Parser/lib/HTML/TokeParser.pm

Rick Umali / www.rickumali.com / rickumali@gmail.com
