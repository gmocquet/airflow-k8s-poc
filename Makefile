SHELL := /bin/bash

KIND_CONFIG ?= infra/kind/cluster.yaml
KIND_CLUSTER_NAME ?= airflow-local
AIRFLOW_NAMESPACE ?= airflow
AIRFLOW_HELM_CHART_RELEASE ?= airflow
AIRFLOW_HELM_CHART_VERSION ?= 1.22.0
AIRFLOW_VERSION ?= 3.2.2
# PostgreSQL image pinned by digest for reproducibility (tags are mutable). Chart 1.22.0 defaults the
# postgresql subchart to bitnamilegacy/postgresql, since Bitnami moved its images out of the free
# Docker Hub repos. This is the digest of the chart default tag 16.1.0-debian-11-r15 (pushed 2025-07-22).
# https://hub.docker.com/layers/bitnamilegacy/postgresql/16.1.0-debian-11-r15/images/sha256-29e3dd0e7e7a740eabdbae6f82673507d180701a719bbdb6d6308a58cf723e64
AIRFLOW_HELM_CHART_POSTGRESQL_VERSION ?= sha256:29e3dd0e7e7a740eabdbae6f82673507d180701a719bbdb6d6308a58cf723e64
AIRFLOW_VALUES ?= infra/values/airflow.yaml
AIRFLOW_HELM_TIMEOUT ?= 10m
AIRFLOW_ENV_FILE ?= infra/env/airflow.env

APPS_DIR ?= apps
APP_BUILD_TAG ?= local

.PHONY: help init run kind-create kind-delete kind-verify-load-persistence airflow-repo airflow-namespace airflow-dags-volume airflow-secret airflow-install airflow-uninstall status metrics-install admin-rbac admin-token destroy

help:
	@printf "Available targets:\n"
	@printf "  init               Create kind cluster and install Airflow\n"
	@printf "  run                Port-forward Airflow webserver to localhost:8080\n"
	@printf "  kind-create        Create the kind cluster\n"
	@printf "  kind-delete        Delete the kind cluster\n"
	@printf "  kind-verify-load-persistence  Prove kind load images survive local docker rmi (KEEP=1 to keep resources)\n"
	@printf "  airflow-install    Install/upgrade Airflow via Helm\n"
	@printf "  airflow-uninstall  Uninstall Airflow\n"
	@printf "  destroy            Delete Airflow and the kind cluster\n"
	@printf "  metrics-install    Install metrics-server for cluster metrics\n"
	@printf "  admin-rbac         Create a local cluster-admin service account\n"
	@printf "  admin-token        Print a token for the local admin service account\n"
	@printf "  status             Show Airflow pods and services\n"
	@printf "  build-apps         Build Docker images for all apps/* using docker buildx\n"
	@printf "  load-apps          Load built app images into the kind cluster\n"

init: kind-create metrics-install airflow-namespace airflow-dags-volume airflow-secret airflow-install admin-rbac

destroy: kind-delete

run:
	@AIRFLOW_WEB_PORT="$$(infra/scripts/airflow_ports.sh)"; \
	if kubectl -n $(AIRFLOW_NAMESPACE) get svc $(AIRFLOW_HELM_CHART_RELEASE)-api-server >/dev/null 2>&1; then \
		SVC="$(AIRFLOW_HELM_CHART_RELEASE)-api-server"; \
	elif kubectl -n $(AIRFLOW_NAMESPACE) get svc $(AIRFLOW_HELM_CHART_RELEASE)-webserver >/dev/null 2>&1; then \
		SVC="$(AIRFLOW_HELM_CHART_RELEASE)-webserver"; \
	else \
		echo "No Airflow UI service found (expected $(AIRFLOW_HELM_CHART_RELEASE)-api-server or $(AIRFLOW_HELM_CHART_RELEASE)-webserver)."; \
		exit 1; \
	fi; \
	echo "Using Airflow UI service: $$SVC"; \
	echo "Using Airflow web port: $${AIRFLOW_WEB_PORT}"; \
	URL="http://localhost:$${AIRFLOW_WEB_PORT}"; \
	echo "Opening $$URL in your default browser..."; \
	echo "Default Airflow UI credentials -> username: admin | password: admin"; \
	( sleep 2; if command -v open >/dev/null 2>&1; then open "$$URL"; elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$$URL"; fi ) & \
	kubectl -n $(AIRFLOW_NAMESPACE) port-forward svc/$$SVC "$${AIRFLOW_WEB_PORT}":8080

kind-create:
	@if kind get clusters | grep -qx "$(KIND_CLUSTER_NAME)"; then \
		echo "kind cluster '$(KIND_CLUSTER_NAME)' already exists; skipping create."; \
	else \
		PROJECT_ROOT="$(PWD)"; \
		tmpfile=$$(mktemp); \
		env PROJECT_ROOT="$${PROJECT_ROOT}" envsubst < $(KIND_CONFIG) > "$${tmpfile}"; \
		kind create cluster --config "$${tmpfile}"; \
		rm -f "$${tmpfile}"; \
	fi

kind-delete:
	@kind delete cluster --name $(KIND_CLUSTER_NAME)

kind-verify-load-persistence:
	@KEEP="$(KEEP)" infra/scripts/verify-kind-load-persistence.sh

airflow-repo:
	@helm repo add apache-airflow https://airflow.apache.org
	@helm repo update

airflow-namespace:
	@kubectl apply -f infra/helm/namespace.yaml

airflow-dags-volume:
	@kubectl apply -f infra/helm/airflow-dags-pv.yaml
	@kubectl apply -f infra/helm/airflow-dags-pvc.yaml

airflow-secret:
	@if [[ ! -f $(AIRFLOW_ENV_FILE) ]]; then \
		echo "Airflow env file '$(AIRFLOW_ENV_FILE)' not found."; \
		exit 1; \
	fi
	@kubectl -n $(AIRFLOW_NAMESPACE) create secret generic airflow-env \
		--from-env-file=$(AIRFLOW_ENV_FILE) \
		--dry-run=client -o yaml | kubectl apply -f -

airflow-install: airflow-repo
	@helm upgrade --install $(AIRFLOW_HELM_CHART_RELEASE) apache-airflow/airflow \
		--version $(AIRFLOW_HELM_CHART_VERSION) \
		--namespace $(AIRFLOW_NAMESPACE) \
		--wait \
		--timeout $(AIRFLOW_HELM_TIMEOUT) \
		--values $(AIRFLOW_VALUES) \
		--set airflowVersion=$(AIRFLOW_VERSION) \
		--set postgresql.image.digest="$(AIRFLOW_HELM_CHART_POSTGRESQL_VERSION)"

metrics-install:
	@infra/scripts/metrics_server.sh

admin-rbac:
	@kubectl apply -f infra/helm/cluster-admin.yaml

admin-token:
	@kubectl -n kube-system create token local-admin

airflow-uninstall:
	@if helm -n $(AIRFLOW_NAMESPACE) status $(AIRFLOW_HELM_CHART_RELEASE) >/dev/null 2>&1; then \
		helm uninstall $(AIRFLOW_HELM_CHART_RELEASE) --namespace $(AIRFLOW_NAMESPACE); \
	else \
		echo "Helm release '$(AIRFLOW_HELM_CHART_RELEASE)' not found; skipping uninstall."; \
	fi

status:
	@kubectl -n $(AIRFLOW_NAMESPACE) get pods
	@kubectl -n $(AIRFLOW_NAMESPACE) get svc

destroy:
	@if kind get clusters | grep -qx "$(KIND_CLUSTER_NAME)"; then \
		$(MAKE) airflow-uninstall; \
		kind delete cluster --name $(KIND_CLUSTER_NAME); \
	else \
		echo "kind cluster '$(KIND_CLUSTER_NAME)' not found; nothing to delete."; \
	fi

build-apps:
	@docker buildx version >/dev/null 2>&1 || { echo "docker buildx not found; please install/enable Docker Buildx."; exit 1; }
	@for appdir in $$(find "$(APPS_DIR)" -maxdepth 1 -mindepth 1 -type d); do \
		if [ -f "$${appdir}/Dockerfile" ]; then \
			appname=$$(basename "$${appdir}"); \
			echo "Building $${appname}..."; \
			docker buildx build --load -t "$${appname}:$(APP_BUILD_TAG)" "$${appdir}"; \
		else \
			echo "Skipping $${appdir} (no Dockerfile)"; \
		fi; \
	done

load-apps:
	@for appdir in $$(find "$(APPS_DIR)" -maxdepth 1 -mindepth 1 -type d); do \
		if [ -f "$${appdir}/Dockerfile" ]; then \
			appname=$$(basename "$${appdir}"); \
			image="$${appname}:$(APP_BUILD_TAG)"; \
			echo "Loading $${image} into kind..."; \
			kind load docker-image --name $(KIND_CLUSTER_NAME) "$${image}"; \
		else \
			echo "Skipping $${appdir} (no Dockerfile)"; \
		fi; \
	done
