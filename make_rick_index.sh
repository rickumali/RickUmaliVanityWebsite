#!/bin/sh

# This SH script builds the full index. Requires blog.tmpl, sports.tmpl, and
# pictures.tmpl
#
# Also requires footer.tmpl, contact.tmpl, bio.tmpl and (of course) rick-yui.tmpl
#
# 2007-12-02 - Original
# 2007-12-08 - Added functions to send e-mail
# 2007-12-10 - Corrected send_err_mail
# 2007-12-18 - Go live
#
# Rick Umali / 2007-12-02

function send_err_mail {
	echo "No Index Created. Missing $1." > msg.$$
	mail -s "Rick Index - No Index Created - Missing $1" rickumali@gmail.com < msg.$$
	rm -f msg.$$
}

function check_file {
	if [ ! -s $1 ]; then
		send_err_mail $1
		return 1
	else
		return 0
	fi
}

check_file bio.tmpl || exit 1
check_file blog.tmpl || exit 1
check_file sports.tmpl || exit 1
check_file pictures.tmpl || exit 1
check_file contact.tmpl || exit 1
check_file footer.tmpl || exit 1
check_file rick-yui.tmpl || exit 1

perl make_new_index.pl > test.html

if [ -s test.html ]; then
	cp -f test.html ../www/index.htm
fi

echo -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= >> generate.log
date >> generate.log
ls -ltr *.tmpl|grep -v start >> generate.log
ls -l test.html >> generate.log
exit 0
