# ローカルプレビュー用のビルド環境。
# ホストに Python パッケージを入れないため、mkdocs は常にこのコンテナ内で動かす。
# 公開ビルド自体は GitHub Actions (.github/workflows/deploy.yml) が行うので、
# このイメージは開発時のプレビュー専用。
FROM python:3.12-slim

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

WORKDIR /docs
EXPOSE 8000
