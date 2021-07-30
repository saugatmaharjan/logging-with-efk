APP_ROOT ?= $(shell 'pwd')

export ELASTIC_SEARCH_PATH = elasticsearch/k8s/overlays/$(STAGE)
export KIBANA_PATH = kibana/k8s/overlays/$(STAGE)
export FLUENT_D_PATH = fluentd/k8s/overlays/$(STAGE)

export FLUENT_D_DOCKER_BUILD_FLAGS ?= --no-cache
export FLUENT_D_DOCKER_BUILD_PATH ?= $(APP_ROOT)
export FLUENT_D_DOCKER_FILE ?= $(APP_ROOT)/fluentd/Dockerfile
export FLUENT_D_SOURCE_IMAGE ?= stride-fluentd
export FLUENT_D_TARGET_IMAGE ?= $(REGISTRY_URL)/$(ECR_REPO_NAME)
export FLUENT_D_TARGET_IMAGE_LATEST ?= $(FLUENT_D_TARGET_IMAGE):$(FLUENT_D_TARGET_IMAGE)

build-fluentd-image:
	@docker build $(FLUENT_D_DOCKER_BUILD_FLAGS) --target  artifact -t $(FLUENT_D_SOURCE_IMAGE) -f $(FLUENT_D_DOCKER_FILE) $(FLUENT_D_DOCKER_BUILD_PATH)

docker-tag-fluentd-image: ## docker tag
	@docker tag $(FLUENT_D_SOURCE_IMAGE) $(FLUENT_D_TARGET_IMAGE_LATEST)

docker-login: ## Login to ECR registry
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(REGISTRY_URL)

update-kubeconfig: ## Update kube config
	@aws eks update-kubeconfig --name=$(EKS_CLUSTER_NAME) --region=$(AWS_REGION)

docker-push-fluentd: ## docker push
	@docker push $(FLUENT_D_TARGET_IMAGE_LATEST)

apply-elasticsearch: ## Deploy Elastic search
	@kubectl apply -f $(ELASTIC_SEARCH_PATH)

apply-kibana: ## Deploy Elastic search
	@kubectl apply -f $(KIBANA_PATH)

apply-fluentd: ## Deploy Elastic search
	@kubectl apply -k $(FLUENT_D_PATH)

publish-custom-fluentd-image: build-fluentd-image docker-tag-fluentd-image docker-login docker-push-fluentd

apply-all: apply-elasticsearch apply-kibana apply-fluentd 

deploy: update-kubeconfig apply-all

clean: ## Remove log file.
	@rm -rf logs/**.log logs/**.json build