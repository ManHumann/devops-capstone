
# Project Title

A complete CI/CD pipeline from code to deploying it in a EC2 server

A simple	web	application	from	source	code	to	a	live deployment	on	AWS	—	provisioned	entirely	through	Infrastructure	as	Code,	containerized,	version-controlled, deployed	via	a	Terraform-provisioned	Jenkins	CI/CD	pipeline,	and	monitored	with	a	self-hosted,	open-source logging	stack	(Grafana	+	Loki).	

## Brief explanation of the approach taken

- A CRUD nodejs + postgress app taken from the repo https://github.com/mahirsust/nodejs-crud-app-backend

- Configured docker compose with init.sql and volumes for consistency with health checks.

- Terraform to automate EC2 creating along with vpc, subnets ,routing , modular security group creation ,tls key creation for remote ssh and loading of custom bash scripts to respective instances.

- Custom bash scripts to download necessary services loaded and initialized to respective instances upon instance creation.

- Selective ports allowed for ingress and egress for security hardening.

- Promtail exporting data for monitoring enstance to log.

- All referencing are done using private ip address as much as possible within the code.

## Running the project 
- After copying the repo setup database credentials in .env file `/CRUD-Nodejs-PostgreSQL` run :
```bash
  cp .env.example .env
``` 
`init.sql` initializes the required tables upon initialization , hence logging into a database and setting up is not required.


- Make sure you have your AWS credentials and configuration setup before hand .

- Ensure the IAM user has all the permissions related to EC2 , S3 and dynamodb.

- In `/Terraform/bootstrap` run 
```bash
  terraform apply
```
This creates the state lock using S3 bucket object and dynamodb

- After initializing the state , move to infrastructure directory to boot up the instances or simpily `cd ../infrastructure` then in directory /`Terraform/infrastructure` run
```bash
  terraform apply
```

- After initializing the servers we need to set the following parameters 
    
    1. Adding jenkins ip to github repo webhook , under repo -> settings -> webhook -> payload URL -> `http://<jenkins_instance_public_ip>:8080/github-webhook/`

    2. Creating github access token under  settings -> developer settings -> personal access token -> Tokens(Classic) -> Generate Token . Make sure repo and admin:org_hook is ticked , store the key in a temporary notepad

    3. Create a similar token but for docker hub , make sure to set access as read write and execute store the key in a temporary notepad.

    4. Optain the Jenkins server private key from `/Terraform/infrastructure` cli using the command `terraform output -raw jenkins_deploy_private_key` store the key in a temporary notepad

- Open up jenkins on browser using `<jenkins-ec2-ip:8080>` and follow the setup instructions , after installation ,add two plugins `SSH AGENT` and `Pipeline Stage View Plugin`

- Setup the credentials for github , docker as `docker-hub-access-token` and SSH Username with private key as `jenkins-server-private-key` as mentioned in the Jenkinsfile in the code . 

- Open up another tab and setup Grafana dashboard using `<grafana-ip>:3000` then setting up the account , setting up connections and explore and setting up 2 queries
    1. `{job="nginx"}`
    2. `{job="jenkins"}`

- Any push to the main repo should start the pipeline to build and deploy the latest image in the deployment server

## Demo

The demo of the project on how to start is presented in this youtube video



