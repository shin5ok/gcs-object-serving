
BUCKET_NAME := $(BUCKET_NAME)
PROJECT_ID := $(PROJECT_ID)

.PHONY: check
check:
	@echo "Checking environmental values..."

.PHONY: deploy
deploy: check
	@echo "Building Cloud Run service of gcs-object-serving"

	gcloud run deploy gcs-object-serving \
	--source=. \
	--region=asia-northeast1 \
	--cpu=0.5 \
	--memory=512M \
	--ingress=internal-and-cloud-load-balancing \
	--set-env-vars=BUCKET_NAME=$(BUCKET_NAME) \
	--min-instances=1 \
	--service-account=gcs-object-serving@$(PROJECT_ID).iam.gserviceaccount.com \
	--allow-unauthenticated

.PHONY: sa
sa: check
	@echo "Make service accounts"

	gcloud iam service-accounts create gcs-object-serving || true
	gcloud iam service-accounts create cloudbuild || true


.PHONY: iam
CLOUDBUILD_SA:=$(shell gcloud builds get-default-service-account | grep gserviceaccount | cut -d / -f 4)
iam: check
	@echo "Grant some authorizations to the service account for Cloud Run service"

	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
	--member=serviceAccount:gcs-object-serving@$(PROJECT_ID).iam.gserviceaccount.com \
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