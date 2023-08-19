# watch

```
crontab -e
```

```
*/5 * * * * /path/to/watch.sh
0 21 * * * /path/to/health.sh
```

## 注） debian の時は以下を実行して No を選択する

```
sudo dpkg-reconfigure dash
```

※ /bin/sh のシンボリックリンクを dash から bash へ変更する
