#!/system/bin/sh

# set up logging
mkdir -p /data/local/tmp/TrustUserCertificates/
exec > /data/local/tmp/TrustUserCertificates/post-fs-data.log
exec 2>&1

# help debugging (print each command to the terminal before executing)
set -x

# module root dir
MODDIR=${0%/*}

# set_context x y --> set the security context of y to match x
set_context() {
    [ "$(getenforce)" = "Enforcing" ] || return 0

    default_selinux_context=u:object_r:system_file:s0
    selinux_context=$(ls -Zd $1 | awk '{print $1}')

    if [ -n "$selinux_context" ] && [ "$selinux_context" != "?" ]; then
        chcon -R $selinux_context $2
    else
        chcon -R $default_selinux_context $2
    fi
}


# clean up possible duplicate mount points
echo "[i] clean up possible duplicate mount points" 
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

echo "[i] looking for user certificates, ignoring versions"

# Read all the certificates ignoring the version.
# Later in the loop, the latest version of each certificate will be identified and copied to the system store
ls /data/misc/user/*/cacerts-added/* | grep -o -E '[0-9a-fA-F]{8}.[0-9]+$' | cut -d '.' -f1 | sort | uniq > /data/local/tmp/TrustUserCertificates/user_certs.txt

echo "[i] found $(cat /data/local/tmp/TrustUserCertificates/user_certs.txt | wc -l) certificates" 

# Android 14 support
echo "[i] checking for cert location in APEX container"
if [ -d /apex/com.android.conscrypt/cacerts ]; then
    # Clone directory into tmpfs
    echo "[i] cert location exists in APEX" 
    echo "[i] copying cert to APEX container" 
    echo "[i] clone directory into tmpfs" 
    mkdir -p /data/local/tmp/TrustUserCertificates/ca
    if mountpoint /data/local/tmp/TrustUserCertificates/ca;then
      echo "[i] /data/local/tmp/TrustUserCertificates/ca mounted" 
      cp -rf /apex/com.android.conscrypt/cacerts/* /data/local/tmp/TrustUserCertificates/ca/
    else
      rm -rf /data/local/tmp/TrustUserCertificates/ca/*
      mount -t tmpfs tmpfs /data/local/tmp/TrustUserCertificates/ca
      cp -rf /apex/com.android.conscrypt/cacerts/* /data/local/tmp/TrustUserCertificates/ca/
    fi
else
    echo "[i] APEX container not found, this must be Android < 14" 
fi

echo "[i] entering loop for copying certificates to system store" 
while read USER_CERT_HASH; do

    echo "[i] attempting to copy ${USER_CERT_HASH}" 

    USER_CERT_FILE=$(ls /data/misc/user/*/cacerts-added/${USER_CERT_HASH}.* | (IFS=.; while read -r left right; do echo $right $left.$right; done) | sort -nr | (read -r left right; echo $right))

    echo "[i] latest version found: ${USER_CERT_FILE}" 

    if ! [ -e "${USER_CERT_FILE}" ]; then
        echo "[e] error finding latest version of ${USER_CERT_HASH}" 
        exit 0
    fi

    echo "[i] delete CAs removed by user or update" 
    rm -f /data/misc/user/*/cacerts-removed/${USER_CERT_HASH}.*

    echo "[i] copy certificates to the old location and set the ownership and permissions" 
    cp -f ${USER_CERT_FILE} ${MODDIR}/system/etc/security/cacerts/${USER_CERT_HASH}.0
    chown -R 0:0 ${MODDIR}/system/etc/security/cacerts
    chmod 644 ${MODDIR}/system/etc/security/cacerts/*
    set_context /system/etc/security/cacerts ${MODDIR}/system/etc/security/cacerts

    # Android 14+ support
    echo "[i] checking for cert location in APEX container" 
    if [ -d /apex/com.android.conscrypt/cacerts ]; then
        echo "[i] copy the cert and set the ownership and permissions" 
        cp -f ${USER_CERT_FILE} /data/local/tmp/TrustUserCertificates/ca/${USER_CERT_HASH}.0
    fi

done </data/local/tmp/TrustUserCertificates/user_certs.txt

# Android 14+ support

echo "[i] checking for cert location in APEX container" 
if [ -d /apex/com.android.conscrypt/cacerts ]; then
    chown -R 0:0 /data/local/tmp/TrustUserCertificates/ca
    set_context /apex/com.android.conscrypt/cacerts /data/local/tmp/TrustUserCertificates/ca

    # Mount directory inside APEX, and remove temporary one.
    echo "[i] mount the directory inside APEX and remove the temp one" 
    if mountpoint /apex/com.android.conscrypt/cacerts;then
      echo "[i] /apex/com.android.conscrypt/cacerts mounted" 
    else
      mount --bind /data/local/tmp/TrustUserCertificates/ca /apex/com.android.conscrypt/cacerts && \
      echo "[i] /apex/com.android.conscrypt/cacerts mount succeeded" 
    fi
    for pid in 1 $(pgrep zygote) $(pgrep zygote64); do
      nsenter --mount=/proc/${pid}/ns/mnt -- \
      /bin/mount --bind /data/local/tmp/TrustUserCertificates/ca /apex/com.android.conscrypt/cacerts
    done
fi

echo "[i] TrustUserCertificates execution completed" 