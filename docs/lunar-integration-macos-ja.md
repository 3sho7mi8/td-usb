# Lunar連携実装ドキュメント（macOS / IWS660-CS）

このドキュメントは、`td-usb` プロジェクトに実装されている Lunar Sensor Mode 連携の現行構成をまとめたものです。

## 1. 目的

IWS660-CS で取得した照度を Lunar に渡し、周囲照度に応じた輝度自動調整を行うことを目的とします。

## 2. 実装アーキテクチャ

```text
IWS660-CS (USB)
  -> LaunchDaemon (root): com.tokyodevices.iws660-bridge
  -> ~/.td-usb/lux
  -> LaunchAgent (user): com.tokyodevices.iws660-lunar
  -> http://127.0.0.1:8000/sensor/ambient_light
  -> Lunar Sensor Mode
```

## 3. コンポーネント

### 3.1 Bridge daemon（root）

- ラベル: `com.tokyodevices.iws660-bridge`
- plist: `launchd/com.tokyodevices.iws660-bridge.plist`
- 実体:
  - `/usr/local/libexec/td-usb/td-usb-root`
  - `/usr/local/libexec/td-usb/iws660-bridge-root.sh`
- 役割:
  - IWS660-CS から照度を取得
  - `~/.td-usb/lux` へ原子的に書き込み
  - `~/.td-usb/bridge.log` へデバッグログ出力

### 3.2 Lunar sensor agent（user）

- ラベル: `com.tokyodevices.iws660-lunar`
- plist: `launchd/com.tokyodevices.iws660-lunar.plist`
- 起動スクリプト: `scripts/start-lunarsensor-agent.sh`
- 役割:
  - `~/.lunarsensor/venv` の uvicorn で API 起動
  - `~/.td-usb/lux` を読み取り `127.0.0.1:8000` で公開

## 4. 主要スクリプト

- `scripts/setup-lunar-integration.sh`
  - lunarsensor と Python venv のセットアップ
  - Lunar の `sensorHostname/sensorPort` 初期設定
- `scripts/install-launchd-services.sh`
  - daemon/agent の plist を実ユーザー環境へ展開
  - `launchctl bootout -> bootstrap -> kickstart` を実施
  - bootstrap 失敗時は再試行し、エラーログを表示
- `scripts/check-launchd-services.sh`
  - daemon/agent のロード状態、`lux`、API 応答を一括確認
- `scripts/iws660-bridge.sh`
  - センサー読み取り、値検証、`lux` の原子的更新
  - root実行時は `LUNAR_LUX_OWNER` へ所有権を合わせる

## 5. 導入手順（推奨）

```bash
make
./scripts/setup-lunar-integration.sh
./scripts/install-launchd-services.sh
./scripts/check-launchd-services.sh
curl -s http://127.0.0.1:8000/sensor/ambient_light
```

## 6. 再起動確認手順

1. macOS本体を再起動（確認対象は以下の2サービス）
   - `com.tokyodevices.iws660-bridge`（system LaunchDaemon）
   - `com.tokyodevices.iws660-lunar`（gui LaunchAgent）
2. ログイン後に次を実行

```bash
./scripts/check-launchd-services.sh
curl -s http://127.0.0.1:8000/sensor/ambient_light
```

期待値:
- daemon/agent とも `running`
- `~/.td-usb/lux` が存在し、値が更新される
- API が `400` ではなく実測照度を返す

## 7. 運用コマンド

```bash
# 状態確認
./scripts/check-launchd-services.sh

# daemon 停止/起動
sudo launchctl bootout system/com.tokyodevices.iws660-bridge
sudo launchctl bootstrap system /Library/LaunchDaemons/com.tokyodevices.iws660-bridge.plist

# agent 停止/起動
sudo launchctl bootout gui/$(id -u)/com.tokyodevices.iws660-lunar
sudo launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.tokyodevices.iws660-lunar.plist
sudo launchctl kickstart -k gui/$(id -u)/com.tokyodevices.iws660-lunar

# ログ確認
sudo tail -f ~/Library/Logs/td-usb/bridge-daemon-error.log
tail -f ~/Library/Logs/td-usb/lunarsensor-agent-error.log
tail -f ~/.td-usb/bridge.log
```

## 8. トラブルシュート

### 8.1 `Bootstrap failed: 5: Input/output error`

- `bootout` 直後の再 `bootstrap` で race が起きる場合があります。
- 現行実装では `install-launchd-services.sh` が待機と再試行を行います。
- 再実行: `./scripts/install-launchd-services.sh`

### 8.2 `command not found: chown`

- daemon側 PATH に `/usr/sbin` が無い場合に発生します。
- 現行実装では bridge と plist の PATH を修正済みです。

### 8.3 API が `400 lx` のまま

- `~/.td-usb/lux` が未更新、または agent未起動の可能性があります。
- `./scripts/check-launchd-services.sh` と `~/.td-usb/bridge.log` を確認してください。

## 9. セキュリティ設計

- USBアクセス権限は root daemon に限定
- API は `127.0.0.1` バインドで LAN 非公開
- `~/.td-usb` は `0700`、`lux` は `0600`
- bridge は `~/.td-usb` / `lux` / `bridge.log` がシンボリックリンクの場合に処理を停止
- `launchd/*.plist` はテンプレート値（`__HOME__` / `__PROJECT_DIR__` / `__USER__`）で管理し、個人パスをコミットしない
- 常用時に `sudo` コマンドを都度実行する必要はありません（導入時のみ管理者認証）

## 10. レガシーモード

- 後方互換として sudoers ベース運用を残しています。
- `./scripts/configure-sudoers.sh` + `./scripts/start-lunar-integration.sh`
- 現在は LaunchDaemon/LaunchAgent 構成を推奨します。
