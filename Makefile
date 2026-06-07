# Spark — developer commands (Phase 6)

SHELL := /bin/bash
SPARK_DESTINATION ?=
export SPARK_DESTINATION

.PHONY: help check lint lint-hig lint-ui-gate lint-perf-gate lint-appstore-gate test test-packages build ci bootstrap deploy-spark-api staging-smoke coverage usecase-tests

help:
	@echo "Spark Makefile targets:"
	@echo "  make check         - secrets + UI + API contract guardrails"
	@echo "  make lint          - SwiftLint (strict)"
	@echo "  make lint-ui-gate  - Gate 2 UI pattern scan (liquid glass + HIG)"
	@echo "  make lint-perf-gate - Gate 3 performance static scan"
	@echo "  make lint-appstore-gate - Gate 4/5 App Store readiness scan"
	@echo "  make test-packages - swift test for all Packages/Spark*"
	@echo "  make usecase-tests - Gate 1: every UseCase referenced in tests"
	@echo "  make coverage      - Gate 1: Domain+Data line coverage ≥ 80%"
	@echo "  make test          - SPM tests + Xcode SparkTests"
	@echo "  make build         - xcodebuild Spark app"
	@echo "  make ci            - lint + test-packages + build + test-app"
	@echo "  make deploy-spark-api - deploy CloudBase spark-api + staging smoke"
	@echo "  make staging-smoke - HTTP smoke against Staging (no deploy)"
	@echo "  make bootstrap     - repo scaffold script"

check:
	./scripts/check-guardrails.sh

lint:
	./scripts/lint.sh

lint-hig:
	./scripts/lint-hig.sh

lint-ui-gate:
	chmod +x scripts/gate2-ui-audit.sh
	./scripts/gate2-ui-audit.sh

lint-perf-gate:
	chmod +x scripts/gate3-perf-audit.sh
	./scripts/gate3-perf-audit.sh

lint-appstore-gate:
	chmod +x scripts/gate4-appstore-audit.sh
	./scripts/gate4-appstore-audit.sh

test-packages:
	./scripts/test-packages.sh

usecase-tests:
	./scripts/check-usecase-tests.sh

coverage:
	SPARK_COVERAGE_GATE=1 ./scripts/check-coverage.sh

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
	chmod +x scripts/deploy-spark-api.sh
	./scripts/deploy-spark-api.sh

staging-smoke:
	./scripts/staging-smoke.sh
