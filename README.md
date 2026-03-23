# TrustUserCertificates
这个Magisk模块将用户安装的证书添加到系统证书存储区和APEX Conscrypt证书存储区，使其在构建信任链时自动被使用。

## 特点

* 支持Magisk/KernelSU/KernelSU Next
* 支持从Android 7到Android 16的设备

根据您的Android版本和Google Play安全更新版本，您的证书将存储在`/system/etc/security/cacerts`或`/apex/com.android.conscrypt/cacerts/`中。此模块处理所有场景，并在任何Android 7到Android 16的设备上都能工作。

## 使用方法

### 安装证书

1. 通过[正常流程](https://support.portswigger.net/customer/portal/articles/1841102-installing-burp-s-ca-certificate-in-an-android-device)安装证书作为用户证书
2. 重启设备或者软重启
3. 证书复制过程会在设备启动时进行
4. 安装的用户证书现在会自动成为系统信任的证书

### 删除证书

通过设置从用户证书存储区中删除证书，并重启设备。模块会自动从系统证书存储区中删除相应的证书。

## 日志和调试

模块运行日志保存在`/data/local/tmp/trust_usercert/trust_usercert.log`中，可用于调试和故障排除。
