#!/usr/bin/env bash
#
# Verify that an image loaded into kind via `kind load docker-image` persists
# in the node's containerd store after the local Docker image is removed.
# This proves that `kind load` duplicates the image into the node, independently
# of the host Docker daemon store.
#
# By default, ALL created resources (kind cluster, demo pod, node image copy and
# the build scratch dir) are removed when the script exits. Pass --keep (or set
# KEEP=1) to preserve everything for inspection instead.
#
# Usage:
#   ./infra/scripts/verify-kind-load-persistence.sh            # run and clean up
#   ./infra/scripts/verify-kind-load-persistence.sh --keep     # run and keep resources
#   KEEP=1 ./infra/scripts/verify-kind-load-persistence.sh     # same, via env var
#
set -euo pipefail

CLUSTER="${CLUSTER:-img-persistence-test}"
IMG="${IMG:-demo-kind-persistence:1.0.0}"
NODE="${CLUSTER}-control-plane"
CONTEXT="kind-${CLUSTER}"
NAME="${IMG%%:*}"
WORKDIR="$(mktemp -d)"
KEEP="${KEEP:-}"

usage() {
  cat <<'EOF'
Verify that a kind-loaded image survives removal of the local Docker image.

By default, ALL created resources (kind cluster, demo pod, node image copy and
the build scratch dir) are removed when the script exits.

Usage:
  verify-kind-load-persistence.sh [--keep]

Options:
  -k, --keep   Preserve all created resources for inspection (no deletion).
               Equivalent to setting KEEP=1 in the environment.
  -h, --help   Show this help and exit.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -k|--keep) KEEP=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

cleanup() {
  if [[ -n "${KEEP}" ]]; then
    echo ">>> --keep set: preserving all created resources."
    echo "    Cluster : $CLUSTER (context: $CONTEXT)"
    echo "    Inspect : kubectl --context $CONTEXT get pod demo"
    echo "              docker exec $NODE crictl images | grep -- $NAME"
    echo "    Scratch : $WORKDIR"
    echo "    Teardown: kind delete cluster --name $CLUSTER"
    return
  fi
  echo ">>> Cleanup: removing all created resources..."
  docker rmi "$IMG" >/dev/null 2>&1 || true
  rm -rf "$WORKDIR"
  kind delete cluster --name "$CLUSTER" >/dev/null 2>&1 || true
}
trap cleanup EXIT

fail() { echo "FAILURE: $*" >&2; exit 1; }

# Colima gotcha: kind create can fail with a log-line timeout when the VM's
# inotify limits are too low. Bump them best-effort before creating the cluster.
preflight_inotify() {
  command -v colima >/dev/null 2>&1 || return 0
  echo "### 0. Preflight: raise Colima inotify limits (best-effort)"
  colima ssh -- sudo sysctl -w fs.inotify.max_user_instances=8192 >/dev/null 2>&1 || true
  colima ssh -- sudo sysctl -w fs.inotify.max_user_watches=524288 >/dev/null 2>&1 || true
}

preflight_inotify

echo "### 1. Disposable kind cluster: $CLUSTER"
kind create cluster --name "$CLUSTER"

# The ServiceAccount admission controller creates the default namespace's
# "default" SA asynchronously after the cluster comes up. Creating a pod before
# it exists fails with "serviceaccount \"default\" not found". Wait for it here;
# the wait overlaps with the build/load steps below, so it adds no real latency.
echo "    Waiting for the default ServiceAccount (avoids a startup race)"
kubectl --context "$CONTEXT" wait --for=create serviceaccount/default --timeout=60s

echo "### 2. Build local image (concrete tag): $IMG"
cat > "$WORKDIR/Dockerfile" <<'EOF'
FROM busybox:1.36
CMD ["sleep", "3600"]
EOF
docker build -t "$IMG" "$WORKDIR"

echo "### 3. Present in the Docker daemon store?"
docker image ls | grep -- "$NAME" || fail "image missing from Docker store after build"

echo "### 4. kind load (export from Docker -> import into node containerd)"
kind load docker-image "$IMG" --name "$CLUSTER"

echo "### 5. Present in the node (containerd via crictl)?"
docker exec "$NODE" crictl images | grep -- "$NAME" || fail "image not loaded into the node"

echo "### 6. Remove the image from the Docker daemon store"
docker rmi "$IMG"

echo "### 7. Absent from Docker?"
if docker image ls | grep -q -- "$NAME"; then
  fail "image is still in the Docker store after docker rmi"
fi
echo "    OK: absent from Docker (expected)"

echo "### 8. STILL present in the kind node?"
docker exec "$NODE" crictl images | grep -- "$NAME" \
  || fail "image disappeared from the node (unexpected result)"
echo "    OK: still in the node = PROOF"

echo "### 9. Ultimate proof: pod with imagePullPolicy=Never"
kubectl --context "$CONTEXT" run demo \
  --image="$IMG" --image-pull-policy=Never --restart=Never
kubectl --context "$CONTEXT" wait --for=condition=Ready pod/demo --timeout=90s \
  || fail "pod is not Ready: the image was not usable from the node"
kubectl --context "$CONTEXT" get pod demo

echo
echo "SUCCESS: the image loaded via kind load survives removal of the local Docker image."
