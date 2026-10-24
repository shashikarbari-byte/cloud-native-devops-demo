IMAGE ?= devops-demo:local

.PHONY: install test lint build run helm-lint tf-fmt tf-validate

install:
	pip install -r app/requirements-dev.txt

test:
	cd app && python -m pytest -q

lint:
	ruff check app

build:
	docker build -t $(IMAGE) .

run: build
	docker run --rm -p 8080:8080 $(IMAGE)

helm-lint:
	helm lint helm/devops-demo
	helm template demo helm/devops-demo > /dev/null

tf-fmt:
	terraform fmt -recursive terraform

tf-validate:
	for d in terraform/aws-eks terraform/azure-aks; do \
	  terraform -chdir=$$d init -backend=false && terraform -chdir=$$d validate; \
	done
