# A Proxy to serve objects from Google Cloud Storage using HTTP/2
This is intented to be a sub component of [ChatUI using Answer API](https://github.com/shin5ok/chatui-using-answerapi).  
Thanks to Cloud Run using HTTP/2, No limitations on the size of objects that can be transferred.

## Prerequisite
- Google Cloud project, billing enabled
- Google Cloud SDK(gcloud command)
- Custom domain that you have authorization

## Preparation
### 1. Clone this repo
On your local environment,
clone this repo and change directory.
```bash
git clone https://github.com/shin5ok/gcs-object-serving; cd gcs-object-serving/
```

### 2. Sign in your Google Cloud Project
Run as below, to get authorization.
```bash
gcloud auth login
```

If you want to test on localhost,
```bash
gcloud auth application-default login
```

### 3. Enable required services
```bash
gcloud services enable run.googleapis.com cloudbuild.googleapis.com
```
It will take a few minutes.

## Setup

### 1. Create service accounts for Cloud Run service.

Make sure where you are in top directory, and then just type this.
```bash
make iam
```
>[!NOTE]
>In this case we just use Cloud Build default service account because just for test.  
>We recommend you prepare a custom service account for Cloud Build for production or staging to project your environment.

### 2. Deploy Cloud Run Service

Prepare environment values.
Database ID is one you wrote down before.
```bash
export BUCKET_NAME=<your bucket name eg: foo-bar>
```
Deploy it.
```bash
make deploy
```
Wait for few minutes until finishing the deployment.

>[!NOTE]
>You cannot access Cloud Run services yet, because the service requires Load Balancer + IAP for security reason.  
>Proceed the next step.

### 5. Configure Identity Aware Proxy(IAP) 
To prevent unauthorized access from the Internet, you can take advantage of IAP.

Follow the link.  
[https://cloud.google.com/iap/docs/enabling-cloud-run?hl=ja](https://cloud.google.com/iap/docs/enabling-cloud-run?hl=ja)  
You can use a SSL certificate provided from Managed certification or Certificate manager.

>[!NOTE]
> You need to disable CDN with the Load Balancer when adopting IAP.

### 6. Test
Open the FQDN of certificate assigned to the Load Balancer with your browser.  
format: https://<your FQDN>/<GCS object key>  
eg: https://gcs-object-serving.eample.com/foo/bar.png
