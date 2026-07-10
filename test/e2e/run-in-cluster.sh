#!/bin/bash
set -e

# Ensure minikube is running
if ! minikube status | grep -q "host: Running"; then
  echo "Minikube is not running. Starting minikube..."
  minikube start
fi

# Ensure we are using the minikube context to avoid affecting production clusters
KUBECTL="kubectl --context minikube"

IMAGE_NAME="quay.io/iamleeg/onthewing-e2e"

echo "Building E2E test image..."
podman build -t $IMAGE_NAME -f Containerfile.e2e .

echo "Loading image into minikube..."
podman save -o /tmp/onthewing-e2e.tar $IMAGE_NAME
minikube image load /tmp/onthewing-e2e.tar

echo "Launching E2E test job..."
$KUBECTL delete job onthewing-e2e-test --ignore-not-found=true
$KUBECTL apply -f test/e2e/e2e-pod.yaml

echo "Waiting for job completion..."
# Wait for the pod to be created and then wait for it to finish
while true; do
  POD_NAME=$($KUBECTL get pods -l job-name=onthewing-e2e-test -o jsonpath='{.items[0].metadata.name}')
  if [ -n "$POD_NAME" ]; then
    break
  fi
  sleep 1
done

$KUBECTL wait --for=condition=complete job/onthewing-e2e-test --timeout=120s || \
$KUBECTL wait --for=condition=failed job/onthewing-e2e-test --timeout=120s

echo "Streaming logs..."
$KUBECTL logs -l job-name=onthewing-e2e-test

# Capture the exit code of the job
STATUS=$($KUBECTL get job onthewing-e2e-test -o jsonpath='{.status.succeeded}')
if [ "$STATUS" == "1" ]; then
  echo "E2E tests passed!"
  exit 0
else
  echo "E2E tests failed!"
  exit 1
fi
