#!perl
#
# make_new_index.pl
#
# Uses the Template Toolkit (TT2) to make a new rickumali.com home page
# from the template rick-bootstrap.tmpl
#
# To use this, say: perl make_new_index.pl > new_index.html
#
# Rick Umali, 2007-11-23
#
use strict;

use Template;

my $tt = Template->new({
    INTERPOLATE  => 1,
    POST_CHOMP  => 1,
}) || die "$Template::ERROR\n";

my $vars = {
    name     => 'Rick Umali',
};

$tt->process('rick-bootstrap.tmpl', $vars)
    || die $tt->error(), "\n";

