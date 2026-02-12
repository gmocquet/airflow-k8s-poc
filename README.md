# airflow-k8s-executor
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
