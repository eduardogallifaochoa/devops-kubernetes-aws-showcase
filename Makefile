.PHONY: up down logs test lint k8s-up k8s-down destroy-all

up:
	docker compose up -d --build

down:
	docker compose down -v

logs:
	docker compose logs -f --tail=100

test:
	pytest -q

lint:
	ruff check .
	black --check .

k8s-up:
	./scripts/kind-up.sh

k8s-down:
	./scripts/kind-down.sh

destroy-all:
	./scripts/destroy-all.sh
