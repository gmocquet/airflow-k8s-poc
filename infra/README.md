# Infrastructure (Kind + Airflow Helm)

This folder contains the local Kubernetes setup (kind) and Helm manifests for Airflow.

## 1) Create the kind cluster

```bash
kind create cluster --config infra/kind/cluster.yaml
```

If you move the repository, update the `hostPath` in `infra/kind/cluster.yaml` to the new absolute path for `dags/`.

## 2) Create namespace and DAGs volume

```bash
kubectl apply -f infra/helm/namespace.yaml
kubectl apply -f infra/helm/airflow-dags-pv.yaml
kubectl apply -f infra/helm/airflow-dags-pvc.yaml
```

## 3) Install metrics-server (for Lens and `kubectl top`)

```bash
make metrics-install
```

## 4) Create a local admin service account (optional, for Lens token auth)

```bash
make admin-rbac
make admin-token
```

## 5) Load environment variables as a Secret

```bash
kubectl -n airflow create secret generic airflow-env \
  --from-env-file=infra/env/airflow.env \
  --dry-run=client -o yaml | kubectl apply -f -
```

## 6) Install Airflow via Helm

```bash
helm repo add apache-airflow https://airflow.apache.org
helm repo update
helm upgrade --install airflow apache-airflow/airflow \
  --namespace airflow \
  --values infra/values/airflow.yaml
```

The chart installs the Kubernetes provider via `airflow.extraPipPackages` (see `infra/values/airflow.yaml`) so `KubernetesPodOperator` works out of the box.

The executor is set to `KubernetesExecutor`; tasks will run as pods. Ensure your task images (e.g., `k8s_kpo_poc:local`) are present in the cluster (use `make build-apps && make load-apps` for kind).

The workers mount the host `apps/` directory into `/opt/airflow/apps` inside worker pods (see `infra/values/airflow.yaml`). The sample `k8s_kpo_poc` DAG calls the CLI via that mount path.

## 7) Access the webserver

```bash
make run
```

The `make run` target picks the first available local port starting at `8080`. If 8080 is busy, it increments until it finds a free port.
If you are running Airflow 3.x, the UI is served by the API server service (`airflow-api-server`), so `make run` will auto-detect it.

For Lens, you can import the kubeconfig from:

```bash
kind get kubeconfig --name airflow-local
```

DAGs are read from the repo `dags/` folder, mounted into the cluster at `/mnt/airflow-dags` and exposed to Airflow at `/opt/airflow/dags`.

## Load local app images into kind

After building app images (e.g., `make build-apps`), load them into the kind cluster:

```bash
make load-apps
```

This makes images like `k8s_kpo_poc:local` available to Airflow tasks without needing an external registry.
