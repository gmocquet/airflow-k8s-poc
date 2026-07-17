# Repository Guidelines

## Project stack and versions
- `uv`: 0.11.29
- `python`: 3.14.6
- `kind`: 0.31.0 - Local Kubernetes providing a realistic environment for Airflow deployment and testing.
- `kubernetes`: 1.35
- `airflow Helm Chart`: 1.22.0
- `airflow`: 3.2.2
- `apache-airflow-providers-cncf-kubernetes`: 10.19.0

- `pre-commit`: 4.6.0
- `ruff`: 0.15.22
- `typer`: 0.27.0
- `pytest`: 9.1.1

- Docker base image: python: `3.14.6-slim-trixie`
  - For uv, use the --copy from method from ghcr.io/astral-sh/uv:trixie-slim 

- Docker 
- Docker buildx 

## Containerize applications

- Each application lives in its own folder under `apps/`.
- Each application has its own `pyproject.toml` for dependencies and tool configuration.
- Applications are independent of Airflow; they can be run as CLI tools using Typer.

## Project structure
- Mono repository 
- dags/: DAG definitions (e.g., `k8s_kpo_poc.py`).
- apps/: CLI applications (Typer). One subfolder per application, isolated from Airflow context.
  - apps/<app_name>/pyproject.toml: Per-app dependency and tool config (uv).
  - apps/<app_name>/src/<app_name>/: Application package (src layout).
  - apps/<app_name>/tests/: Per-app pytest suites.
- infra/: Infrastructure assets for Airflow/Kubernetes (helm charts, kind configs, values).
  - infra/helm/
  - infra/kind/
  - infra/values/

## Python dependency management
- Managed with `uv`, per-app `pyproject.toml`.
- Dependency groups: `default` and `dev`.
- `ruff` is the single tool for linting and formatting.

## Makefile
- Root `Makefile` provides quick-start and common workflows.
- Expected targets: `init`, `build-apps`, `load-apps`, `run`, `destroy` (and any helper targets as needed).
