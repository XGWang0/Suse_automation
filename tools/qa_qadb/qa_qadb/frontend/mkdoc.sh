#!/bin/sh

phpdoc -t doc/qadb_api/ -o HTML:default:default -f tblib_db.php,tblib_html.php,tblib_common.php,tblib.php,qadb.php -dn QADB
#phpdoc -t doc/tblib_api/ -o HTML:default:default -f tblib_db.php,tblib_html.php,tblib_common.php,tblib.php,qadb.php -dn TBLib

#phpdoc -t doc/ -o HTML:default:default -f tblib_db.php,tblib_html.php,tblib_common.php,tblib.php,qadb.php -dn QADB
#phpdoc -t doc/ -o HTML:default:default -f tblib_db.php,tblib_html.php,tblib_common.php,tblib.php,qadb.php -dn TBLib

#phpdoc -t doc/ -o HTML:default:default -f qadb.php
#phpdoc -t doc/ -o HTML:default:default -f tblib_db.php,tblib_html.php,tblib_common.php,tblib.php,qadb.php
