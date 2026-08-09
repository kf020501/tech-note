IMAGE := tech-note-mkdocs

# ホストと同じUID/GIDで実行する。root所有のファイルが site/ に残るのを防ぐため。
# HOME=/tmp は mkdocs がキャッシュを書ける場所を与えるため。
DOCKER_RUN := docker run --rm \
	-u $(shell id -u):$(shell id -g) \
	-e HOME=/tmp \
	-v $(PWD):/docs \
	-w /docs

.PHONY: help image serve build clean

help: ## このヘルプを表示
	@grep -E '^[a-zA-Z0-9_.-]+:.*## ' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS=":.*## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

image: ## プレビュー用Dockerイメージをビルド（初回・requirements.txt変更時のみ）
	docker build -t $(IMAGE) .

serve: image ## ローカルプレビューを起動 http://127.0.0.1:8000
	$(DOCKER_RUN) -it -p 8000:8000 $(IMAGE) \
		mkdocs serve --dev-addr 0.0.0.0:8000

build: image ## site/ にビルド（公開はされない。確認用）
	$(DOCKER_RUN) $(IMAGE) mkdocs build

clean: ## ビルド成果物を削除
	rm -rf site
