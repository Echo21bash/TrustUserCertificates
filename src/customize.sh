#!/system/bin/sh
# set up logging
set -x
mkdir -p /data/local/tmp/TrustUserCertificates/
exec > /data/local/tmp/TrustUserCertificates/customize.log
exec 2>&1

rm "$MODPATH/system/etc/security/cacerts/.keep"