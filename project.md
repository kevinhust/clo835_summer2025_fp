CLO835
Final Project: Deployment of 2-tiered web
application to managed K8s cluster on
Amazon EKS, with pod auto-scaling and
deployment automation.
CLO835
Submission
Instructions
To be submitted via Blackboard. Refer to Blackboard for
submission instructions
Value 20% of final grade
Learning Outcomes Covered in Assignment
• Design, implement and deploy containerized applications to address cost
optimization, high availability, and scalability requirements of business
applications
• Explain containerization concept and its implementation on Linux OS to
support efficient application releases cycle.
• Evaluate the applicability of containerization approach and viability of
publicly/privately hosted containers orchestration platform for the business
needs of the organization.
• Analyze security, observability, and operational challenges of modern cloud
native serverless solutions.
• Implement application resources requirements for compute, storage and
memory to ensure cost efficient utilization of cloud infrastructure
• Implement application deployment pipeline for containerized applications to
cloud hosted and managed Kubernetes cluster to support business needs and
to reduce time to market
• Evaluate and recommend networking, persistent storage, and IAM (Identity
and Access Management) solutions to achieve the desired level of
infrastructure and applications security.
Integrity Pledge:
By submitting my Final Project, I affirm that I will not give or receive any unauthorized help in this submission and that all work provided will be my own and my group’s. I
CLO835
agree to abide by Seneca’s Academic Integrity Policy, and I understand that any violation of academic integrity will be subject to the penalties outlined in the policy. Click on this link to learn more about Seneca's Academic Integrity Policy: Academic
Integrity Policy
Assignment High Level Outline
The objective of the Final Project is to combine everything we learned so far in the
scope of CLO835 about building, hosting, and deploying a containerized application
using K8s orchestration tool and Docker.
In this assignment, you will enhance an existing web application backed by MySQL
DB and add configuration, security, and persistent data features. You will build the
Docker image of the enhanced application automatically using GitHub Actions and
publish it to the private docker registry hosted by Amazon ECR.
You will create Amazon EKS cluster to host the application.
To deploy the application to Amazon EKS cluster, you will create all the relevant
manifests and deploy them using kubectl client.
Application code and deployment manifests should be stored in GitHub repos. You
can use the same repo or different repos to store application code and deployment
manifests.
Demonstrate the required functionality by recording the deployment process and
showcasing the application functionality.
Assignment Detailed Outline
The Final Project includes the sections below:
1. Enhance the web application introduced in Assignment 1 of the course to do the
following:
• The HTML pages should display a background image in place of background
color. The implementation example can be found in the References section.
• Receive the location of the background image stored in the private S3 bucket
from the ConfigMap.
CLO835
2. 3. 4. 5. • The background image should be stored in a private S3 bucket. The
application should retrieve the image from the private bucket and use it as a
background image.
You can achieve this by going through the steps below:
a. Provide the image location via ConfigMap
b. Write some code that gets the images from the bucket using the
information in the ConfigMap and stores the image local. Provide AWS
credentials as K8s secrets to allow access to the private S3 bucket.
c. The app loads the image from the local storage
The implementation example can be found in the References section.
• Add logs entry that prints out the background image URL
• Pass MySQL DB username and password to the Flask application as K8s
secrets
• Come up with a name and a slogan for your group. Add the name and the
slogan of your group name to the header of the HTML, pass it as
Environment variable using ConfigMap
• Your Flask application should listen on port 81.
Create Dockerfile, docker image and test the application locally in your Cloud9
environment.
Store your application in GitHub and create a GitHub Action that builds and
tests your application. Upon successful unit test, GitHub Action publishes your
image to Amazon ECR.
Create Amazon EKS cluster with 2 worker nodes and a namespace “fp”.
Create the following K8s manifests and deploy the respective K8s resources:
• ConfigMap to provide the application with background image URL
• Secrets:
o MySQL DB username and password
o AWS credentials to allow access to the private S3 bucket
o Imagepull secret to work with the private Amazon ECR repository
CLO835
• PersistentVolumeClaim based on gp2 default StorageClass with the
characteristics below:
o Size: 3Gi
o AccessMode: ReadWriteOnce
• Create serviceaccount named “clo835_sa”
• K8s role (Role or ClusterRole, whichever is appropriate) “CLO835” with
permissions to create and read namespaces. Create a binding (RoleBinding or
ClusterRoleBinding, whichever appropriate) that binds the “CLO835” role to
the clo835_sa serviceaccount.
• Deployment of MySQL DB with 1 replica and volume based on PVC
(Persistent Volume Claims) created in step 3.
• Service that exposes MySQL DB to the Flask application. Choose the service
type. Remember to use ConfigMap and Secret in this manifest.
• Deployment of Flask application with 1 replica from the image stored in
Amazon ECR.
• Service that exposes the Flask application to the Internet users and has a
stable endpoint. Choose the service type.
6. Verify that your flask application is successfully loading via browser.
7. Replace your background image in the S3 bucker, update ConfigMap with the
new image name. Make sure the new image is reflected in the browser.
The Final Project has 5 main parts :
1. 2. 3. 4. Enhancing the application to add configurable background and secrets
Creating Docker image build and publishing automation with GitHub Actions
Granting application access to an image stored in a private AmazonS3 bucket
Creating and deploying application manifests using kubectl client
You will use the services and tools below:
• GitHub to store your application’s code and K8s manifests
CLO835
• GitHub Actions to automate build and publishing of application’s image
• Docker cli to build the image, test it locally and as part of GitHub Actions and
publish it to Amazon ECR
• Amazon ECR to securely store your Docker images
• Amazon EKS to host your application
• Amazon EBS to provide persistent storage for MySQL DB
• Amazon S3 to store image that your application uses as a background
• AWS IAM to grant application access to you private Amazon S3 bucket
• Cloud9 IDE or your local environment to develop your application and build
container images
• kubectl to work with your Amazon EKS cluster
• eksctl to create and delete your cluster
CLO835
Architecture Diagram
CLO835
Submission
Your submission should include the following:
Link(s) to your public GitHub repo(s) with the relevant manifests and
application code
Link to the recording(s) that capture all the functionality described in the
Recording section below.
You recording is a demo. It needs to be a video with audio and you explain the
items that you are doing as you go.
Detailed report with issues faced and fixed during implementation with
screenshots
Important Notes – please read carefully:
• Make sure there are no credentials pushed to GitHub repo at any stage!
• The assignment might be challenging. Please start ASAP.
• All the commits should have dates before the Final Project due date
• There should be a sequence of commits in your GitHub repo that reflects the
progression of your assignment. Submissions with a small number of commits
will raise authenticity questions.
• Add meaningful messages to your commits that reflect the added functionality
or the fixes you made.
• Make sure your recording is up to 30 minutes long.
CLO835
Submission Requirements Description
GitHub Repo links
Task Submission Requirements Description
1. Enhance the simple-web-
mysql application
GitHub repo with enhanced web application code
3. Store your application in
GitHub and create a GitHub
Action that builds and tests
GitHub Actions workflow that builds and publishes
application image to Amazon ECR upon every
commit to main branch
your application. Upon
successful unit test, GitHub
Action publishes your image
to Amazon ECR.
5. Create the following K8s
GitHub repo with all the required manifests
manifests and deploy the
respective K8s resources.
Important: make sure your main branch is protected and direct commits to main branch
are not allowed.
CLO835
Recording
Description
The recording should clearly demonstrate the points below:
1. 2. Application functionality is verified locally using docker images
Application image is created automatically and pushed to Amazon
ECR using GitHub Actions.
3. 4. Application is deployed into empty namespace “fp” in Amazon EKS.
Application is loading the background image from a private Amazon
S3
5. Data is persisted when the pod is deleted and re-created by the
replicaset, Amazon EBS volume and K8s PV (PersistentVolume) are
created dynamically when application pod is created
6. 7. Internet users can access the application
Change the background image URL in the ConfigMap. Make sure a
new image is visible in the browser.
Plagiarism:
Plagiarized assignments will receive a mark of zero on the assignment and a failing
grade on the course. You may also receive a permanent note of plagiarism on your
academic record.
Tasks Checklist
1. Enhance the application to do the following:
1.1. Receive the location of the background image from ConfigMap.
1.2. The background image should be stored in a private S3 bucket
1.3. Add logs entry that prints out the background image location
1.4. Pass MySQL DB username and password to the Flask application as K8s secrets
1.5. Add your name to the header of the HTML, pass it as Environment variable
using ConfigMap
1.6. Your Flask application should listen on port 81.
2. 3. 4. 5. 6. 7. 8. 9. CLO835
Create Dockerfile, docker image and test the application locally in your Cloud9
environment.
Store your application in GitHub and create a GitHub Action that builds and tests
your application. Upon successful unit test, GitHub Action publishes your image to
Amazon ECR.
Create Amazon EKS cluster with 2 worker nodes and a namespace “fp”.
Create the following K8s manifests and deploy the respective K8s resources:
5.1. ConfigMap to provide the application with background image URL
5.2. Secrets:
5.2.1.MySQL DB username and password
5.2.2.AWS credentials to allow access to the private S3 bucket
5.2.3.Imagepull secret to work with the private Amazon ECR repository
5.3. PersistentVolumeClaim based on gp2 default StorageClass with the
characteristics below:
Size: 3Gi
AccessMode: ReadWriteOnce
5.4. Create 5.5. Deployment of MySQL DB with 1 replica and volume based on PVC (Persistent
serviceaccount named “clo835_sa”
Volume Claims) created in step 3.
5.6. Service that exposes MySQL DB to the Flask application. Choose the service
type. Remember to use ConfigMap and Secret in this manifest.
5.7. Deployment of Flask application with 1 replica from the image stored in
Amazon ECR.
5.8. Service that exposes the Flask application to the Internet users and has a stable
endpoint. Choose the service type.
Verify that data is persisted when the MySQL pod is deleted and re-created by the
replicaset, Amazon EBS volume and K8s PV (PersistentVolume) are created
dynamically when application pod is created
Verify that your flask application is successfully loading via browser.
Replace your background image in the S3 bucket, update ConfigMap with the new
image. Make sure the new image is reflected in the browser.
The report with authentic recount of the challenges faced during the assignment
along with screenshots
CLO835
Appendix
Recommended implementation flow
User Access to Amazon EKS API :
1. 2. 3. 4. 5. 6. 7. 8. Create the application and test it locally. You might want to remove MySQL
connectivity at this point
Deploy Amazon EKS cluster using eksctl tool, verify the worker nodes are ready
Create a GitHub Actions workflow that builds, sts and publishes the application
image. Use Amazon ECR to host the image
Create deployment manifests using hard-coded values as a first step
Verify Amazon S3 bucket access from within the container
Replace hard-coded values with dynamic values from ConfigMap and Secret
Deploy the application and verify all the functionality required
Change the background image URL in configMap, delete the pod and make sure
a new background image is visible in the browser
References:
https://stackabuse.com/file-management-with-aws-s3-python-and-flask/
https://github.com/jimini55/catsdogs-cloud9