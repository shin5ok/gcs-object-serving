
NAME := gcs-object-serving
BUCKET_NAME := $(BUCKET_NAME)
PROJECT_ID := $(PROJECT_ID)

.PHONY: check
check:
	@echo "Checking environmental values..."
	# woule implement in the future

.PHONY: deploy
deploy: check
	@echo "Building Cloud Run service of $(NAME)"

	gcloud beta run deploy $(NAME) \
	--source=. \
	--region=asia-northeast1 \
	--cpu=1 \
	--memory=1G \
	--ingress=internal-and-cloud-load-balancing \
	--set-env-vars=BUCKET_NAME=$(BUCKET_NAME) \
	--service-account=$(NAME)@$(PROJECT_ID).iam.gserviceaccount.com \
	--cpu-boost \
	--no-default-url \
	--use-http2 \
	--allow-unauthenticated

.PHONY: sa
sa: check
	@echo "Make service accounts"

	gcloud iam service-accounts create $(NAME) || true
	gcloud iam service-accounts create cloudbuild || true


.PHONY: iam
CLOUDBUILD_SA:=$(shell gcloud builds get-default-service-account | grep gserviceaccount | cut -d / -f 4)
iam: check
	@echo "Grant some authorizations to the service account for Cloud Run service"

	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
	--member=serviceAccount:$(NAME)@$(PROJECT_ID).iam.gserviceaccount.com \
	--role=roles/storage.objectUser

	@echo "Grant some authorizations to the service account for Cloud Build"

	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
	--member=serviceAccount:$(CLOUDBUILD_SA) \
	--role=roles/artifactregistry.repoAdmin

	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
	--member=serviceAccount:$(CLOUDBUILD_SA) \
	--role=roles/cloudbuild.builds.builder

	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
	--member=serviceAccount:$(CLOUDBUILD_SA) \
	--role=roles/run.admin

	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
	--member=serviceAccount:$(CLOUDBUILD_SA) \
	--role=roles/storage.admin
