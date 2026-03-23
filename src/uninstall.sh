#!/system/bin/sh
exec > /data/local/tmp/trust_usercert/trust_usercert_uninstall.log
exec 2>&1
set -x
# module root
MODDIR=${0%/*}
rm -rf ${MODDIR}/system/etc/security/cacerts/*
while true; do
  sleep 3
  if mountpoint /apex/com.android.conscrypt/cacerts;then
    umount /apex/com.android.conscrypt/cacerts
  else
    break
  fi
done

while true; do
  sleep 3
  if mountpoint /data/local/tmp/trust_usercert/ca;then
    umount /data/local/tmp/trust_usercert/ca
  else
    break
  fi
done
