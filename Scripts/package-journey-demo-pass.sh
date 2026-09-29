#!/usr/bin/env bash
# 导出「剧本杀：情感本」演示 Pass 的未签名包，供 Pass Builder / signpass 签名。
# 用法：
#   1. 模拟器或真机跑一遍 App（会写入 Documents/UnsignedWalletPasses/）
#   2. 从模拟器容器拷出 .pkpass，或在本脚本签名后放回：
#      Documents/SignedWalletPasses/D0000000-0000-4000-8000-000000000013.pkpass
#   3. 也可将签名后的包放入 坐标系/Resources/DemoWalletPasses/script-murder-journey-demo.pkpass 并重新编译
#
# 若本机已配置 Pass 签名证书，可设置：
#   export PASS_SIGNING_IDENTITY="Apple Wallet: …"
#   export PASS_SIGNING_CERT="path/to/cert.pem"
#   export PASS_SIGNING_KEY="path/to/key.pem"
#   export PASS_SIGNING_WWDR="path/to/AppleWWDRCA.pem"
# 然后执行本脚本对未签名包签名。

set -euo pipefail

SERIAL="D0000000-0000-4000-8000-000000000013"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${ROOT}/坐标系/Resources/DemoWalletPasses"
UNSIGNED="${OUT_DIR}/${SERIAL}-unsigned.pkpass"
SIGNED="${OUT_DIR}/script-murder-journey-demo.pkpass"

mkdir -p "$OUT_DIR"

if [[ -f "${HOME}/Library/Developer/CoreSimulator/Devices" ]]; then
  echo "提示：在模拟器跑完 App 后，可从以下路径查找未签名包："
  echo "  ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Documents/UnsignedWalletPasses/${SERIAL}.pkpass"
fi

if [[ -n "${PASS_SIGNING_CERT:-}" && -n "${PASS_SIGNING_KEY:-}" && -n "${PASS_SIGNING_WWDR:-}" && -f "$UNSIGNED" ]]; then
  if command -v openssl >/dev/null 2>&1; then
  WORK="$(mktemp -d)"
  unzip -q "$UNSIGNED" -d "$WORK"
  openssl smime -binary -sign \
    -certfile "$PASS_SIGNING_WWDR" \
    -signer "$PASS_SIGNING_CERT" \
    -inkey "$PASS_SIGNING_KEY" \
    -in "$WORK/manifest.json" \
    -out "$WORK/signature" \
    -outform DER -nodetach
  (cd "$WORK" && zip -q -r "$SIGNED" .)
  rm -rf "$WORK"
  echo "已签名：$SIGNED"
  echo "重新编译 App 后，启动时会自动复制到 SignedWalletPasses。"
  else
    echo "需要 openssl 才能签名。"
    exit 1
  fi
else
  echo "未配置 PASS_SIGNING_* 或未找到 $UNSIGNED"
  echo "请先用 App 生成未签名包，或把已签名的 .pkpass 放到："
  echo "  $SIGNED"
fi
