#!/system/bin/sh

# module root dir
MODDIR=${0%/*}
rm ${MODDIR}/system/etc/security/cacerts/.keep

