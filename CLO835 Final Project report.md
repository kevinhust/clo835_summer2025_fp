# CLO835 Final Project Report

**Student:** Zhihuai Wang  
**Student ID:** 178000238 
**Date:** August 10, 2025

## 1. Introduction

The objective of this Final Project is to combine everything learned in CLO835 about building, hosting, and deploying a containerized application using Kubernetes (K8s) orchestration and Docker. This project involves enhancing an existing two-tiered web application (web and MySQL DB), automating its Docker image build and publishing to Amazon ECR using GitHub Actions, provisioning an Amazon EKS cluster, and deploying the application to EKS with advanced features like ConfigMaps, Secrets, Persistent Volumes, and auto-scaling. The project emphasizes modern DevOps practices, high availability, scalability, and security in a cloud-native environment.

## 2. Project Implementation Details

### 2.1 Application Enhancement

*   **Background Image from S3 via ConfigMap & Secrets:**
    *   HTML pages display a background image.
    *   Image location received from ConfigMap.
    *   Image stored in a private S3 bucket.
    *   Application retrieves image from S3 using AWS credentials provided as K8s Secrets.
    *   Logs entry prints out the background image URL.
*   **MySQL DB Credentials as K8s Secrets:**
    *   MySQL DB username and password passed to Flask application as K8s Secrets.
*   **Group Name & Slogan via ConfigMap:**
    *   Group name and slogan added to the HTML header, passed as Environment variables using ConfigMap.
*   **Flask Application Port:**
    *   Flask application listens on port 8080 (changed from 81 for non-root user compatibility).

### 2.2 Docker Image Build and Publishing Automation

*   **Dockerfile Creation:** Dockerfile created for the enhanced Flask application.
*   **Local Testing:** Application tested locally in Cloud9 environment using Docker.
*   **GitHub Actions Workflow:**
    *   GitHub Action created to build and test the application.
    *   Upon successful unit test, GitHub Action publishes the image to Amazon ECR.

### 2.3 Amazon EKS Cluster Provisioning and K8s Manifests

*   **EKS Cluster Creation:** Amazon EKS cluster created with 2 worker nodes and a namespace "fp".
*   **K8s Manifests Deployment:**
    *   **ConfigMap:** For background image URL, group name, and slogan.
    *   **Secrets:**
        *   MySQL DB username and password.
        *   AWS credentials for S3 access.
        *   ImagePullSecret for private Amazon ECR repository.
    *   **PersistentVolumeClaim (PVC):** Based on `gp2` StorageClass (Size: 3Gi, AccessMode: ReadWriteOnce).
    *   **ServiceAccount:** Named "clo835-sa" (updated for RFC1123 compliance).
    *   **Role/ClusterRole & Binding:** "CLO835" role (or ClusterRole) with permissions to create and read namespaces, bound to "clo835-sa" serviceaccount.
    *   **MySQL DB Deployment:** 1 replica, with volume based on PVC.
    *   **MySQL Service:** Exposes MySQL DB to Flask application (Service Type: ClusterIP). Uses ConfigMap and Secret.
    *   **Flask Application Deployment:** 1 replica, from image stored in Amazon ECR.
    *   **Flask Application Service:** Exposes Flask application to Internet users with a stable endpoint (Service Type: LoadBalancer).

### 2.4 Verification and Functionality Demonstration

*   Flask application successfully loads via browser.
*   Data persistence verified for MySQL DB (pod deletion/re-creation).
*   Background image change reflected after ConfigMap update.

## 3. Challenges Faced and Solutions

### 3.1 Challenge A: MySQL 8.0 Container Startup Failures

**Description:**
The initial deployment used MySQL 8.0, which consistently failed to start in the containerized EKS environment. Pods entered CrashLoopBackOff state with errors like "Unable to determine if daemon is running: Inappropriate ioctl for device" and "Failed to start mysqld daemon". This issue persisted across multiple troubleshooting attempts including resource reduction, configuration simplification, and forced pod cleanup.

**Screenshot:**
*![image-20250810112439642](/Users/kevinwang/Library/Application Support/typora-user-images/image-20250810112439642.png)*

**Solution:**
Switched from MySQL 8.0 to MySQL 5.7 image, which is more stable in containerized environments. Additionally improved health check probes by:

- Adding proper authentication parameters to health checks (`-u root --password=clo835_password123`)
- Increasing probe timeouts and delays (livenessProbe: 90s initial delay, readinessProbe: 45s)
- Using more conservative probe intervals to allow proper MySQL initialization
This resolved all MySQL startup issues and achieved stable 1/1 Ready status.

### 3.2 Challenge B: Flask Application Permission Denied on Port 81

**Description:**
The Flask application initially configured to run on port 81 failed to start with "Permission denied" errors. This occurred because ports below 1024 require root privileges, but the Dockerfile implemented security best practices by running the application as a non-root user (`appuser`). The webapp pods repeatedly crashed with CrashLoopBackOff status.

**Screenshot:**
![image-20250810112544016](/Users/kevinwang/Library/Application Support/typora-user-images/2.png)

**Solution:**
Changed the Flask application port from 81 to 8080, which can be used by non-root users. Updated the following configurations:

- `app.py`: Modified `app.run(host='0.0.0.0',port=8080,debug=False,threaded=True)`
- `Dockerfile`: Updated `EXPOSE 8080` and health check URLs
- `webapp-deployment.yaml`: Changed containerPort to 8080
- `webapp-service.yaml`: Updated targetPort to 8080
This maintained security by using a non-root user while enabling proper application startup.

## 4. Additional Notes

*   **GitHub Repository Link:**
    *   Complete Project: https://github.com/kevinhust/clo835_summer2025_fp
    *   Contains application code, Kubernetes manifests, Dockerfile, and GitHub Actions workflow
    
* **Recording Link:** [clo835final.mp4](https://seneca-my.sharepoint.com/:v:/g/personal/zwang342_myseneca_ca/EZt2bBUc1ZNGsHZMYexjVrQBS9Tfa6fRM-twOMiC6ooHgQ?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=OaVvPU)

  

---