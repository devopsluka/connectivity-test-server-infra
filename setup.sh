#!/bin/bash

VALUES_FILE="./values.yaml"
NAMESPACE=$(yq eval '.namespace' "$VALUES_FILE")

echo "Starting Minikube..."
minikube start --kubernetes-version=v1.31.0

echo "Installing Tekton Pipelines..."
kubectl apply --filename --validate=false https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

echo "Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" || echo "Namespace $NAMESPACE already exists."

echo "Waiting for Tekton pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n tekton-pipelines --timeout=300s

echo "Updating namespace context"
kubectl config set-context --current --namespace="$NAMESPACE"

echo "Adding Installing Helm chart..."
helm install connectivity-server .

echo "Setup Complete. Verify your deployments using kubectl or Helm commands."
