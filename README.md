# 前提

| OS     | Domain    |
| ------ | --------- |
| debian | cloud dns |

- システムファイルの操作を行うため、以下の環境で作業を行う

```sh
sudo su -
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
sudo usermod -aG docker ${対象ユーザー名 whoami}
```
追加されたかの確認
```
groups ${対象ユーザー名}
```

※ 次に再起動するまで sudo ありで docker コマンドが必要。snapd インストール時に再起動するのでその時に。

# nginx の設定

nginx の install

```sh
apt-get update && apt-get install -y nginx
```

domain の 設定
ここで設定しておくと Let's Encrypto の設定がスムーズ

```sh
vi /etc/nginx/sites-available/default
```

以下の 例のように 80 番のみで一旦作成し、 nginx を再起動する

```
server {
    listen 80;
	  server_name cms.symbol-community.com;
	  location / {
		  proxy_pass	http://localhost:1337/;
	  }
}

server {
    listen 80;
		server_name symbol-community.com;
		root /var/www/html;
		location / {
			try_files $uri $uri/ =404;
		}
}
```

nginx の起動

```sh
systemctl start nginx && systemctl enable nginx
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

# nginx --> docker 設定

nginx を リバースプロキシとして 実行中のコンテナ へ接続する
同一の web app を複数稼働可能にする

```
vi /etc/nginx/sites-available/default
```

以下の通りリバースプロキシを追加していく

```
server {
	  server_name cms.symbol-community.com;
	  location / {
		  proxy_pass	http://localhost:1337/;
	  }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/symbol-community.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/symbol-community.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}

server {
		server_name symbol-community.com;
		root /var/www/html;
		location / {
			try_files $uri $uri/ =404;
		}

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/symbol-community.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/symbol-community.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}

server {
    if ($host = symbol-community.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

		listen 80;
		server_name symbol-community.com;
			return 404; # managed by Certbot

}
server {
    if ($host = cms.symbol-community.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

		listen 80;
		server_name cms.symbol-community.com;
			return 404; # managed by Certbot
}
```

nginx を再起動する

```
systemctl restart nginx.service
```
