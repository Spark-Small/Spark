# CN Auth SDK setup (iOS App target)

Native SDK binaries are **not** committed. Add them under `Vendor/` (gitignored) and enable compile flags in `Secrets.xcconfig`.

## WeChat Open SDK

1. Download [WeChat Open SDK iOS](https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/iOS.html) → `Vendor/WechatOpenSDK/WechatOpenSDK.xcframework`
2. Link in Xcode → Spark target → Frameworks
3. In `Secrets.xcconfig`:
   ```
   WECHAT_APP_ID = your_app_id
   WECHAT_UNIVERSAL_LINK = https://your.domain/app/wechat/
   SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) SPARK_HAS_WECHAT_SDK
   ```
4. Register URL scheme `wx$(WECHAT_APP_ID)` in WeChat Open Platform

## Aliyun phone one-tap (DYPNS / ATAuthSDK)

1. Enable [号码认证服务](https://help.aliyun.com/product/75010.html) → download iOS SDK
2. Place under `Vendor/AliyunPhoneAuth/`
3. ```
   ALIYUN_PHONE_AUTH_SDK_KEY = your_sdk_key
   SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) SPARK_HAS_ALIYUN_PHONE_SDK
   ```

## Tencent phone one-tap

1. [腾讯云号码认证](https://cloud.tencent.com/product/ns) → iOS SDK under `Vendor/TencentPhoneAuth/`
2. ```
   TENCENT_PHONE_AUTH_APP_ID = your_app_id
   SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) SPARK_HAS_TENCENT_PHONE_SDK
   ```

## Alipay Open SDK

1. [支付宝开放平台](https://opendocs.alipay.com/open/218/welcome) → iOS SDK under `Vendor/AlipaySDK/`
2. ```
   ALIPAY_APP_ID = your_app_id
   SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) SPARK_HAS_ALIPAY_SDK
   ```

## Primary phone provider

```
PHONE_ONE_TAP_PRIMARY = aliyun
```

Facade tries primary SDK first, then fallback provider.

## Staging bridge (no SDK)

When `SPARK_CN_AUTH_STAGING_BRIDGE = 1` and no vendor IDs are set, Live builds against Staging use magic tokens documented in [STAGING.md](STAGING.md). **Not for production.**

## Backend env vars

See `cloudfunctions/spark-api/lib/auth-providers.js` — `WECHAT_APP_SECRET`, `ALIYUN_PHONE_AUTH_*`, `TENCENT_PHONE_AUTH_*`, `ALIPAY_*`.
