# k8s-airflow
Airflow running on k8s with KubernetesExecutor

## Prerequisites (host tools)
- `docker` with Compose & Buildx enabled (Docker Desktop or Colima)
- `kind` ≥ 0.31.0
- `kubectl`
- `helm` (for the Airflow chart)
- `uv` ≥ 0.9.29 (Python dependency management)
- `python` ≥ 3.14

### Colima quick start (if not using Docker Desktop)
```bash
brew install colima docker docker-buildx
colima start --cpu 4 --memory 8 --disk 60
docker context use colima
docker buildx create --name colima-builder --driver docker-container --use
docker buildx inspect --bootstrap
```

### Verify buildx
```bash
docker buildx version
docker buildx ls
```

### Getting started

1. Setup the local Airflow cluster
```bash
make init && make build-apps && make load-apps
```

2. Launch the local Airflow stack
```bash
make run
```

3. Clean up resources
```bash
make destroy && docker system prune -a --volumes && colima delete
```
