# Setup Script for Minikube and Tekton Pipelines

This script automates the setup of a Minikube Kubernetes cluster, the installation of Tekton Pipelines, and the deployment of a Helm chart in a specified namespace.

## Prerequisites

To successfully run this script, ensure that the following dependencies are installed on your machine:

1. **Minikube**  
   Install Minikube to create a local Kubernetes cluster.  
   [Installation guide for Minikube](https://minikube.sigs.k8s.io/docs/start/)

2. **Kubectl**  
   Kubernetes command-line tool to interact with your cluster.  
   [Installation guide for Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

3. **Helm**  
   Helm package manager for Kubernetes to manage charts.  
   [Installation guide for Helm](https://helm.sh/docs/intro/install/)

4. **YQ**  
   Command-line YAML processor to extract values from YAML files.  
   [Installation guide for YQ](https://mikefarah.gitbook.io/yq/)

5. **Tekton CLI (tkn)**  
   CLI tool for interacting with Tekton Pipelines.  
   [Installation guide for Tekton CLI](https://tekton.dev/docs/cli/)

## Usage

1. Clone this repository and navigate to the script's directory.

2. Ensure the `values.yaml` file is present in the script's directory. The file should contain a `namespace` key used to set up the Kubernetes namespace.

3. Run the setup script:

   ```bash
   ./setup-script.sh
   ```

## Tekton Pipeline Overview

The Tekton Pipeline defined in this project automates the build, deployment, and testing of the application. Here’s a breakdown of the pipeline’s main tasks:

### Tasks

1. **git-clone**  
   Clones the specified Git repository and branch (defined in `values.yaml`) into a workspace.

2. **git-version**  
   Determines the Git version for tagging the built image. Runs after the `git-clone` task.

3. **build-and-push**  
   Builds and pushes the Docker image to the specified registry with the Git version tag. Runs after the `git-version` task.

4. **test-deployment**  
   Deploys the built image to a Kubernetes deployment named `test-{{ .Release.Name }}` and updates the deployment in the specified namespace.

5. **test-service**  
   Tests the deployed service by pinging a specified endpoint. This task verifies the service's availability and status after deployment.

6. **upgrade-deployment**  
   Upgrades the main deployment after successful testing. Runs after `test-service`.

### `test-deployment` Task

The `test-deployment` task is responsible for deploying the built container image to a Kubernetes deployment in the test environment. It also retrieves the service URL for the deployment, which is used by the `test-service` task.

#### Parameters

- **image**: The container image to use for the deployment.
- **deployment-name**: Name of the Kubernetes deployment for the test environment.
- **namespace**: Namespace for the deployment (from `values.yaml`).
- **service-name**: The name of the service associated with the deployment.

#### Results

- **service-url**: The URL of the deployed service.

#### Steps

1. **update-deployment**: Updates the deployment in the specified namespace to use the new image.
2. **wait-for-deployment**: Waits for the deployment to be fully ready, then retrieves the service URL for further testing.

### `test-service` Task

The `test-service` task validates the deployed service by pinging its `/ping` endpoint. It ensures that the service is accessible and responding as expected.

#### Parameters

- **service-url**: The URL of the service to ping, retrieved from the `test-deployment` task.

#### Steps

1. **ping-service**: Sends a request to the service at `http://<service-url>:8080/ping`. It checks if the service responds with a status code of `200`, indicating successful deployment. Any other status code results in a failure.


## Infrastructure Resiliency and Auto-Scaling

To ensure that our application is resilient to compute node failures and can automatically scale in response to high CPU utilization, we use Kubernetes features like HorizontalPodAutoscaler (HPA) and configure our deployment with resource requests and limits.

### Horizontal Pod Autoscaling (HPA)

The HorizontalPodAutoscaler (HPA) automatically adjusts the number of replicas in the deployment based on CPU utilization. Here’s how it is set up:

- **Minimum and Maximum Replicas**: We define a minimum of 3 replicas to maintain high availability and handle some level of traffic, even if a node fails. The HPA can scale up to a maximum of 10 replicas based on load.
- **CPU-Based Scaling**: The HPA monitors the average CPU utilization across all pods. When it exceeds the target utilization (70% in our case), additional replicas are created to share the load. This allows the application to handle traffic spikes effectively.
