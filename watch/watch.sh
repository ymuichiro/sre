#!/bin/bash

slack_webhook_url="https://hooks.slack.com/services/***************"
node_url="https://***************"
web_url="https://***************"

# REST Requst
nodeRes=`curl -L $node_url  -w '\n%{http_code}' -s`
nodeBody=`echo "$nodeRes" | sed '$d'`
nodeStatus=`echo "$nodeRes" | tail -n 1`

# Check if "apiNode" is "down" in the JSON data
apiNode_status=$(echo "$nodeBody" | jq -r '.status.apiNode')
db_status=$(echo "$nodeBody" | jq -r '.status.db')

if [ "$nodeStatus" != "200" ] || [ "$apiNode_status" = "down" ] || [ "$db_status" = "down" ]; then
    messages=("[ 障害通知 ]" "" "ノード $node_url にて $nodeStatus エラーを検出しました。")
    joined_messages=$(printf "%s\n" "${messages[@]}")
    curl -X POST -H 'Content-type: application/json' -d "{\"text\": \"$joined_messages\"}" $slack_webhook_url
fi


# REST Requst
webRes=`curl -L $web_url  -w '\n%{http_code}' -s`
webBody=`echo "$webRes" | sed '$d'`
webStatus=`echo "$webRes" | tail -n 1`

# Check if "apiNode" is "down" in the JSON data
web_status=$(echo "$webBody" | jq -r '.status')

if [ "$webStatus" != "200" ] || [ "$web_status" = "down" ]; then
    messages=("[ 障害通知 ]" "" "ノード $web_url にて $webStatus エラーを検出しました。")
    joined_messages=$(printf "%s\n" "${messages[@]}")
    curl -X POST -H 'Content-type: application/json' -d "{\"text\": \"$joined_messages\"}" $slack_webhook_url
fi
