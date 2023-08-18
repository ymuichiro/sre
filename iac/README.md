# Cron と Shell で コンテナを更新時に差し替える

## 作成した定期実行 shell ファイルに実行権限を振る

```shell
chmod 700 /path/to/your/script.sh
```

## cron を更新する

設定ファイルを開く

```shell
sudo crontab -e
```

設定を追記する

```
*/5 * * * * /path/to/your/script.sh
```
