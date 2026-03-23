#!/system/bin/sh
# set up logging
set -x
mkdir -p /data/local/tmp/trust_usercert/
exec > /data/local/tmp/trust_usercert/trust_usercert_pr.log
exec 2>&1

rm "$MODPATH/system/etc/security/cacerts/.keep"