# インフラの道具（AWS CLI と Terraform）を入れたコンテナ。ホストには入れない。
# 使い方: docker compose run --rm tools で中のシェルに入り、aws login --remote、terraform plan などを公式どおりに打つ。
# バージョンを上げるときは、この 2 つの FROM のタグだけを変える。

# Terraform は単体で動くバイナリなので、公式イメージから取り出す。S3 backend が aws login の認証情報を読めるのは 1.15.0 から
FROM hashicorp/terraform:1.17.1 AS terraform

# aws login は AWS CLI 2.32.0 から
FROM amazon/aws-cli:2.39.3
COPY --from=terraform /bin/terraform /usr/local/bin/terraform

# ホストのユーザー（compose.yaml の user）で動かすので、誰でも書ける HOME を用意する。~/.aws はホストから渡す
RUN mkdir -p /home/infra && chmod 1777 /home/infra
ENV HOME=/home/infra
# コンテナの中にいることがプロンプトで分かるようにする（例: [tools] /work$）
ENV PS1='[tools] \w\$ '

WORKDIR /work
ENTRYPOINT []
CMD ["bash"]
