#!/system/bin/sh
exec > /data/local/tmp/TrustUserCertificates/uninstall.log
exec 2>&1
set -x
# module root
MODDIR=${0%/*}
echo "[i] clean ${MODDIR}/system/etc/security/cacerts/"
rm -rf ${MODDIR}/system/etc/security/cacerts/*
while true; do
  sleep 1
  if mountpoint /apex/com.android.conscrypt/cacerts;then
    echo "[i] umount /apex/com.android.conscrypt/cacerts"
    umount /apex/com.android.conscrypt/cacerts
  else
    break
  fi
done

while true; do
  sleep 1
  if mountpoint /data/local/tmp/TrustUserCertificates/ca;then
    echo "[i] umount /data/local/tmp/TrustUserCertificates/ca"
    umount /data/local/tmp/TrustUserCertificates/ca
  else
    break
  fi
done
