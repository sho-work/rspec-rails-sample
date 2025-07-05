# rspec-rails-sample
railsプロジェクトにrspecを追加する例

## 環境構築
### 前提条件
docker-compose CLI を使えるようにして下さい。

### 構築手順
1. cloneしてディレクトリを移動します。
```bash
# sshの場合
$ git clone git@github.com:sho-work/rspec-rails-sample.git
$ cd rspec-rails-sample/src
```

2. imageをbuildします。
```bash
$ docker compose build
```

3. DBのセットアップを行います。
```bash
$ docker compose exec web bin/rails db:create
$ docker compose exec web bin/rails db:migrate


$ docker compose exec web bin/rails db:create RAILS_ENV=test
$ docker compose exec web bin/rails db:migrate RAILS_ENV=test
```

もしくは、
```bash
$ bin/setup-db
```

4. コンテナを起動する
```bash
$ docker compose up
```

5. localhost:3000 にアクセスしてrailsのお馴染みの画面が表示されていれば環境構築完了です！ 🎉

## Tips
### rails consoleに入りたい。
```bash
$ docker compose exec web bin/rails c
```
もしくは、
```bash
$ bin/rails-console
```
