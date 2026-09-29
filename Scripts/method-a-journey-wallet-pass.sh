#!/usr/bin/env bash
# 方式 A：剧本杀情感本 → 真 Wallet Pass
# 1) 编译并启动 App，生成未签名 .pkpass
# 2) 复制到桌面，供 Pass Builder 签名
# 3) 签名后执行：./Scripts/method-a-journey-wallet-pass.sh install-signed /path/to/signed.pkpass

set -euo pipefail

SERIAL="D0000000-0000-4000-8000-000000000013"
BUNDLE_ID="app.zuobiaoxi.coordinate"
SCHEME="坐标系"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="${PROJECT_DIR}/坐标系.xcodeproj"
DEST="${PROJECT_DIR}/坐标系/Resources/DemoWalletPasses"
DESKTOP_UNSIGNED="${HOME}/Desktop/坐标系-剧本杀情感本-unsigned.pkpass"
SIGNED_BUNDLE_NAME="script-murder-journey-demo.pkpass"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro}"

usage() {
  cat <<EOF
用法:
  $0                     # 编译、启动 App、导出未签名包到桌面
  $0 install-signed <signed.pkpass>   # 安装已签名包到模拟器 + 工程 Resources

Pass Builder 签名要点:
  • Pass Type ID 须为: pass.coordinate.app
  • Team ID 须与 PassConfiguration.teamIdentifier 一致 (A95ZH5QY7B)
  • 签名后文件名任意，用 install-signed 子命令安装即可

安装完成后: 模拟器内打开「我的 → 活动凭证 → 剧本杀：情感本 → 我的行程」
            点右上角钱包图标 → 系统「添加到 Apple Wallet」
EOF
}

find_unsigned_in_simulators() {
  find "${HOME}/Library/Developer/CoreSimulator/Devices" \
    -path "*/Documents/UnsignedWalletPasses/${SERIAL}.pkpass" 2>/dev/null \
    | while read -r f; do
        echo "$f"
      done
}

latest_unsigned() {
  find_unsigned_in_simulators | while read -r f; do
    stat -f '%m %N' "$f"
  done | sort -rn | head -1 | cut -d' ' -f2-
}

boot_simulator() {
  xcrun simctl boot "$SIMULATOR_NAME" 2>/dev/null || true
  xcrun simctl bootstatus "$SIMULATOR_NAME" -b
}

build_and_launch() {
  echo "▶ 编译…"
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=${SIMULATOR_NAME}" \
    -quiet build

  local app_path
  app_path="$(find "${HOME}/Library/Developer/Xcode/DerivedData" \
    -path '*Build/Products/Debug-iphonesimulator/坐标系.app' -type d 2>/dev/null | head -1)"
  if [[ -z "$app_path" ]]; then
    echo "找不到 坐标系.app" >&2
    exit 1
  fi

  boot_simulator
  echo "▶ 安装并启动 App…"
  xcrun simctl install booted "$app_path"
  xcrun simctl launch booted "$BUNDLE_ID" >/dev/null
  sleep 4
}

export_unsigned() {
  local src
  src="$(latest_unsigned)"
  if [[ -z "$src" || ! -f "$src" ]]; then
    echo "未找到未签名包。请先运行不带参数的本脚本。" >&2
    exit 1
  fi
  mkdir -p "$DEST"
  cp "$src" "$DESKTOP_UNSIGNED"
  cp "$src" "${DEST}/${SERIAL}-unsigned.pkpass"
  echo "✓ 未签名包已复制到:"
  echo "    $DESKTOP_UNSIGNED"
  echo "    ${DEST}/${SERIAL}-unsigned.pkpass"
  echo ""
  echo "下一步: 用 Apple Pass Builder 打开并签名该文件，然后执行:"
  echo "  $0 install-signed /path/to/签名后.pkpass"
}

install_signed() {
  local signed_src="$1"
  if [[ ! -f "$signed_src" ]]; then
    echo "文件不存在: $signed_src" >&2
    exit 1
  fi

  if ! unzip -l "$signed_src" | grep -q ' signature$'; then
    echo "✗ 该 .pkpass 未包含 signature 文件（仍是未签名包）。" >&2
    echo "  请先用 Pass Builder 签名后再执行 install-signed。" >&2
    exit 1
  fi

  echo "▶ 校验 PKPass 能否加载…"
  local verify_out
  verify_out="$(swift -e '
import Foundation
import PassKit
let data = try! Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
do {
  let pass = try PKPass(data: data)
  print("OK \(pass.serialNumber)")
} catch {
  print("FAIL \(error.localizedDescription)")
  exit(1)
}
' "$signed_src" 2>&1)" || {
    echo "✗ PKPass 校验失败: $verify_out" >&2
    exit 1
  }
  echo "✓ PKPass 校验通过 ($verify_out)"

  mkdir -p "$DEST"
  cp "$signed_src" "${DEST}/${SIGNED_BUNDLE_NAME}"
  cp "$signed_src" "${DEST}/${SERIAL}.pkpass"

  boot_simulator
  local data_container
  data_container="$(xcrun simctl get_app_container booted "$BUNDLE_ID" data)"
  local signed_dir="${data_container}/Documents/SignedWalletPasses"
  mkdir -p "$signed_dir"
  cp "$signed_src" "${signed_dir}/${SERIAL}.pkpass"

  echo "✓ 已签名包已安装到:"
  echo "    工程: ${DEST}/${SIGNED_BUNDLE_NAME}"
  echo "    模拟器: ${signed_dir}/${SERIAL}.pkpass"
  echo ""
  echo "▶ 重新启动 App 以加载 Pass…"
  xcrun simctl launch booted "$BUNDLE_ID" >/dev/null
  echo "完成。请打开「我的行程」→ 点钱包图标加入 Apple Wallet。"
}

case "${1:-}" in
  "" )
    usage
    echo ""
    build_and_launch
    export_unsigned
    ;;
  install-signed )
    [[ $# -ge 2 ]] || { echo "请提供已签名 .pkpass 路径" >&2; exit 1; }
    install_signed "$2"
    ;;
  -h|--help|help )
    usage
    ;;
  * )
    echo "未知子命令: $1" >&2
    usage
    exit 1
    ;;
esac
