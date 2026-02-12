# K8s KPO PoC CLI

A Typer-based CLI used as a KubernetesPodOperator PoC (greet + sleep).

## Quick Start

```bash
uv run --project . k8s-kpo-poc hello
uv run --project . k8s-kpo-poc sleep --seconds 10
uv run --project . k8s-kpo-poc product sample
```

## Commands

- `hello`: print a greeting
- `sleep`: sleep for the given seconds (used by the KubernetesPodOperator demo)
- `product sample`: print a demo product payload as JSON

## Development

```bash
uv run --project . python -m pytest
uv run --project . ruff check .
uv run --project . ruff format .
```

## Build container

```bash
docker buildx build --load -t k8s_kpo_poc:local .
```
