# 前提

| OS     | Domain    |
| ------ | --------- |
| debian | cloud dns |

# ユーザーの作成

## 現在 root である場合

```sh
adduser -m -p ${パスワード入力} user
groupadd wheel
usermod -g wheel user
sudo su user
```

## su 可能なユーザーを絞る

```sh
sudo vi /etc/pam.d/su
```
次の行をコメント解除する `auth       required   pam_wheel.so`

※ 本番環境時は作業の完了時に wheel の剥奪を行なう

## その他確認する事

- root user にパスワードは設定されているか
- 時刻同期（timesyncd）は有効であるか
- タイムゾーンの設定や locale は正しいか

## 共通の前処理

```shell
sudo apt update
sudo apt-get update
```

# Docker の 設定

```sh
sudo apt-get update && sudo apt-get install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

docker groups が存在するか？確認

```
cat /etc/group | grep docker
```

ないとき

```
sudo groupadd docker
```

ユーザーの追加

```
sudo usermod -aG docker $(whoami)
```

追加されたかの確認

```
groups $(whoami)
```

※ 次に再起動するまで sudo ありで docker コマンドが必要。snapd インストール時に再起動するのでその時に。

# nginx の設定

nginx の install

```sh
sudo apt-get update && sudo apt-get install -y nginx
```

domain の 設定
ここで設定しておくと Let's Encrypto の設定がスムーズ

```sh
sudo vi /etc/nginx/sites-available/default
```

以下の 例のように 80 番のみで一旦作成し、 nginx を再起動する

```
server {
    listen 80;
	  server_name domain.com;
	  location / {
		  proxy_pass	http://localhost:1337/;
	  }
}

server {
    listen 80;
		server_name domain.com;
		root /var/www/html;
		location / {
			try_files $uri $uri/ =404;
		}
}
```

nginx の起動

```sh
sudo systemctl start nginx && sudo systemctl enable nginx
```

# Let's Encrypto の設定

```sh
sudo apt update && sudo apt install snapd
sudo snap install core && sudo snap refresh core;
sudo reboot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot --nginx
```

test

```sh
sudo certbot renew --dry-run
```

nginx を再起動する

```
systemctl restart nginx.service
```
