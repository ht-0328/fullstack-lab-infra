# fullstack-lab-infra

AWS のインフラ（Terraform と、AWS CLI と Terraform を入れた道具のコンテナ）。[fullstack-lab](https://github.com/ht-0328/fullstack-lab) の一部で、集約リポジトリの `infra/` に submodule として入ります。全体の構成は fullstack-lab の README を、何を作るかは fullstack-lab の設計の文書 [docs/design/infra/](https://github.com/ht-0328/fullstack-lab/blob/main/docs/design/infra/README.md) を、作る順序と進み具合は issue [fullstack-lab#13](https://github.com/ht-0328/fullstack-lab/issues/13) を参照してください。

## 道具のコンテナ

AWS CLI と Terraform はホストに入れず、[Dockerfile](Dockerfile) のイメージに入れます。中に入って、公式のドキュメントどおりにコマンドを打ちます。

```bash
cd infra                        # fullstack-lab から使うとき。このリポジトリの直下で打つ
docker compose run --rm tools   # 中のシェルに入る（初回はイメージを作る）
```

入るとプロンプトが `[tools] /work$` に変わります。

`exit` でコンテナから出ます。`--rm` なので、出るとコンテナは消えます。

| 項目 | 内容 |
|---|---|
| バージョン | Dockerfile の 2 つの `FROM` のタグで固定する（AWS CLI 2.39.3、Terraform 1.17.1）。Dockerfile を変えたら `docker compose run --rm --build tools` で作り直す |
| 作業ディレクトリ | コンテナの `/work` がこのリポジトリ |
| 動かすユーザー | ホストのユーザー（既定は uid 1000）。違うときは `HOST_UID` と `HOST_GID` を渡す |

## ログイン

初めて使うときと、期限が切れたときは、コンテナの中で次を打ちます。

```bash
aws login --remote
aws sts get-caller-identity   # Arn が user/Administrator で終われば成功
```

1. 表示された URL を、ホストのブラウザで開きます。
2. IAM ユーザーでサインインします。アカウント ID、ユーザー名、パスワードの順に入れます。
3. ブラウザに出たコードをターミナルに貼り、Enter を押します。

パスワードはブラウザにだけ入れます。ターミナルには入れません。

### いつログインし直すか

ログインの結果は、ホストの `~/.aws`（コンテナには `/home/infra/.aws` として渡す）に保存されます。コンテナを消しても、イメージを作り直しても、ログインはそのまま残ります。

| 起きること | ログインし直すか |
|---|---|
| `exit` でコンテナを出て、また入る | 要らない |
| イメージを作り直す | 要らない |
| 15 分ごとの認証情報の期限 | 要らない。AWS CLI が自動で更新する |
| サインインから最大 12 時間（IAM ユーザーのセッションの長さ）が過ぎる | 要る。`aws` や `terraform` が認証エラーで止まる |
| ホストの `~/.aws/login/cache` を消す | 要る |

期限は AWS の文書「[Login for AWS local development using console credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sign-in.html)」に書かれています。手元から AWS を操作しない日は、`aws logout` で保存した認証情報を消せます。

## 公開のリポジトリなので出さないもの

アカウント ID、アクセスキー、`~/.aws` の中身（ログインの認証情報）、state（`*.tfstate`）、state のバケット名を書く `backend.hcl` は、git にもログにも出しません。`.gitignore` で除いています。

## テスト

| 種類 | 実行 | 確認すること |
|---|---|---|
| 形式と構文 | CI（PR と main への push。[.github/workflows/ci.yml](.github/workflows/ci.yml)） | 道具のイメージが作れる。`terraform fmt -check` と、`*.tf` のあるディレクトリごとの `terraform validate` が通る |

CI は AWS に接続しません。`terraform init -backend=false` で初期化し、AWS の認証情報を使わずに書き方の誤りだけを見ます。手元で同じことを確かめるときは、コンテナの中で `terraform fmt -check -recursive` を打ちます。
