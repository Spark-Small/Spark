# Spark — developer commands (Phase 6)

SHELL := /bin/bash
SPARK_DESTINATION ?= platform=iOS Simulator,name=iPhone 17,OS=26.4.1
export SPARK_DESTINATION

.PHONY: help check lint test test-packages build ci bootstrap

help:
	@echo "Spark Makefile targets:"
	@echo "  make check         - secrets + UI + API contract guardrails"
	@echo "  make lint          - SwiftLint (strict)"
	@echo "  make test-packages - swift test for all Packages/Spark*"
	@echo "  make test          - SPM tests + Xcode SparkTests"
	@echo "  make build         - xcodebuild Spark app"
	@echo "  make ci            - lint + test-packages + build + test-app"
	@echo "  make bootstrap     - repo scaffold script"

check:
	./scripts/check-guardrails.sh

lint:
	./scripts/lint.sh

test-packages:
	./scripts/test-packages.sh

test: test-packages test-app

test-app:
	./scripts/test-app.sh

build:
	./scripts/build-app.sh

ci:
	./scripts/ci.sh

bootstrap:
	chmod +x scripts/spark-init-repo.sh
	./scripts/spark-init-repo.sh
