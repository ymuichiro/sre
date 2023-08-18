#!/bin/bash
cat "$0"

# 注意事項
# - 本スクリプトは対象のコンテナが1つである時に利用する
# - 対象のコンテナが複数ある場合は、コンテナ名を指定してコンテナを差し替える必要がある

# 変数
last_image_hash_file="last_image_hash.txt"
remote_image_url="alpine:latest"
slack_webhook_url="https://hooks.slack.com/services/***********"

# 前回のイメージハッシュを読み込む
if [ -f "$last_image_hash_file" ]; then
    last_image_hash=$(cat "$last_image_hash_file")
else
    last_image_hash=""
fi

# リモートイメージのハッシュを取得
old_container_id=$(docker ps -q)
remote_image_hash=$(docker pull $remote_image_url | awk '/Digest:/ {print $2}')

# エラーハンドリング関数
handle_error() {
    echo "エラーが発生しました。"

    curl -X POST -H 'Content-type: application/json' -d "{\"text\": \"エラーが発生しています。古いコンテナイメージで起動します。\"}" $slack_webhook_url

    if [ -n "$old_container_id" ]; then
        echo "古いコンテナを再起動します。"
        docker start "$old_container_id"
    else
        echo "古いコンテナが存在しないため、スクリプトを終了します。"
        exit 1
    fi
}

# エラー時の処理を登録
trap 'handle_error' ERR

# 前回のハッシュと比較
if [ "$remote_image_hash" != "$last_image_hash" ] && [ -n "$remote_image_hash" ]; then

    # コンテナ差し替え
    echo "更新を検知しました。コンテナを差し替えます。"
    docker stop $(docker ps -a -q)
    docker rm $(docker ps -a -q)
    # コンテナの起動を試みる
    if ! docker run -d -p 3000:3000 $remote_image_url; then
        # エラー発生時の処理をトリガー
        handle_error
    fi

    # 後処理
    docker image prune -a -f

    if [ -n "$slack_webhook_url" ]; then
        messages=("[ 更新通知 ]" "" "コンテナイメージ $remote_image_url を更新しました。" "最新の Hash は $remote_image_hash です")
        joined_messages=$(printf "%s\n" "${messages[@]}")
        curl -X POST -H 'Content-type: application/json' -d "{\"text\": \"$joined_messages\"}" $slack_webhook_url
    fi
    
    # 新しいハッシュをファイルに保存
    echo "リモートイメージが更新されました！"
    echo "$remote_image_hash" > "$last_image_hash_file"
else
    echo "リモートイメージは更新されていません。"
fi
