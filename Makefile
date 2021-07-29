APP_ROOT ?= $(shell 'pwd')

export ELASTIC_SEARCH_PATH = elasticsearch/k8s
export KIBANA_PATH = kibana/k8s
export FLUENT_D_PATH = fluentd/k8s/overlays/$(STAGE)

export FLUENT_D_DOCKER_BUILD_FLAGS ?= --no-cache
export FLUENT_D_DOCKER_BUILD_PATH ?= $(APP_ROOT)
export FLUENT_D_DOCKER_FILE ?= $(APP_ROOT)/fluentd/Dockerfile
export FLUENT_D_SOURCE_IMAGE ?= stride-fluentd
export FLUENT_D_TARGET_IMAGE ?= $(REGISTRY_URL)/$(ECR_REPO_NAME)
export FLUENT_D_TARGET_IMAGE_LATEST ?= $(FLUENT_D_TARGET_IMAGE):$(FLUENT_D_TARGET_IMAGE)

use-kubectl-minikube-context: ## Use kubectl Minikube context
	@kubectl config use-context minikube

create-kubernetes-namespace: ## Create Kubenetes namespace: fleuntd
	-kubectl create namespace stride-logging

build-fluentd-image:
	@docker build $(FLUENT_D_DOCKER_BUILD_FLAGS) --target  artifact -t $(FLUENT_D_SOURCE_IMAGE) -f $(FLUENT_D_DOCKER_FILE) $(FLUENT_D_DOCKER_BUILD_PATH)

docker-tag-fluentd-image: ## docker tag
	@docker tag $(FLUENT_D_SOURCE_IMAGE) $(FLUENT_D_TARGET_IMAGE_LATEST)

docker-login: ## Login to ECR registry
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(REGISTRY_URL)

docker-push-fluentd: ## docker push
	@docker push $(FLUENT_D_TARGET_IMAGE_LATEST)

deploy-elasticsearch: ## Deploy Elastic search
	@kubectl apply -f $(ELASTIC_SEARCH_PATH)

deploy-kibana: ## Deploy Elastic search
	@kubectl apply -f $(KIBANA_PATH)

deploy-fluentd: ## Deploy Elastic search
	@kubectl apply -k $(FLUENT_D_PATH)

publish-custom-fluentd-image: build-fluentd-image docker-tag-fluentd-image docker-login docker-push-fluentd

start: use-kubectl-minikube-context create-kubernetes-namespace deploy-elasticsearch deploy-kibana deploy-fluentd 