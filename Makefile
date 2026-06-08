# Spark — developer commands (Phase 6)

SHELL := /bin/bash
SPARK_DESTINATION ?= platform=iOS Simulator,name=iPhone 17,OS=26.5
export SPARK_DESTINATION

.PHONY: help check lint lint-hig test test-packages build ci bootstrap deploy-spark-api staging-smoke

help:
	@echo "Spark Makefile targets:"
	@echo "  make check         - secrets + UI + API contract guardrails"
	@echo "  make lint          - SwiftLint (strict)"
	@echo "  make lint-hig      - SwiftLint HIG rules (swiftlint_hig.yml)"
	@echo "  make test-packages - swift test for all Packages/Spark*"
	@echo "  make test          - SPM tests + Xcode SparkTests"
	@echo "  make build         - xcodebuild Spark app"
	@echo "  make ci            - lint + test-packages + build + test-app"
	@echo "  make bootstrap     - repo scaffold script"
	@echo "  make deploy-spark-api - redeploy cloudfunctions/spark-api to CloudBase"
	@echo "  make staging-smoke - HTTP smoke against SPARK_API_BASE_URL"

check:
	./scripts/check-guardrails.sh

lint:
	./scripts/lint.sh

lint-hig:
	./scripts/lint-hig.sh

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

deploy-spark-api:
	cd cloudfunctions/spark-api && npm install --omit=dev
	npx mcporter call cloudbase.manageFunctions action=updateFunctionCode functionName=spark-api functionRootPath="$(CURDIR)/cloudfunctions"

staging-smoke:
	./scripts/staging-smoke.sh
