#!/bin/bash

set -ex

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update
# Install both CRDs and KubeRay operator v1.5.1.
helm install kuberay-operator kuberay/kuberay-operator --version 1.5.1

set +ex
