#!/bin/bash

VALUES_FILE="./values.yaml"
NAMESPACE=$(yq eval '.namespace' "$VALUES_FILE")

echo "Starting Minikube..."
minikube start --kubernetes-version=v1.31.0

echo "Installing Tekton Pipelines..."
kubectl apply -f "https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml"

echo "Installing Tekton Triggers..."
kubectl apply -f "https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml"

echo "Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" || echo "Namespace $NAMESPACE already exists."

echo "Waiting for Tekton Pipeline CRDs to be ready..."
until kubectl get crd pipelineruns.tekton.dev >/dev/null 2>&1; do
  echo "Waiting for Pipeline CRDs to be established..."
  sleep 5
done

echo "Waiting for Tekton Trigger CRDs to be ready..."
until kubectl get crd eventlisteners.triggers.tekton.dev >/dev/null 2>&1; do
  echo "Waiting for Trigger CRDs to be established..."
  sleep 5
done

echo "Waiting for Tekton Pipeline pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n tekton-pipelines --timeout=300s

echo "Waiting for Tekton Trigger pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n tekton-triggers --timeout=300s

echo "Updating namespace context"
kubectl config set-context --current --namespace="$NAMESPACE"

echo "Installing Helm chart..."
helm install connectivity-server .

echo "Setup Complete. Verify your deployments using kubectl."

echo "Running pipeline"
sleep 5
tkn pipeline start connectivity-server-pipeline --use-pipelinerun connectivity-server-pipelinerun
