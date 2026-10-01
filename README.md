
# Project Title

A complete CI/CD pipeline from code to deploying it in a EC2 server

A simple	web	application	from	source	code	to	a	live deployment	on	AWS	—	provisioned	entirely	through	Infrastructure	as	Code,	containerized,	version-controlled, deployed	via	a	Terraform-provisioned	Jenkins	CI/CD	pipeline,	and	monitored	with	a	self-hosted,	open-source logging	stack	(Grafana	+	Loki).	

## Brief explanation of the approach taken

- A CRUD nodejs + postgress app taken from the repo https://github.com/mehreentahir16/CRUD-Nodejs-PostgreSQL.git

- Configured docker compose with init.sql and volumes for consistency with health checks.

- Terraform to automate EC2 creating along with vpc, subnets ,routing , modular security group creation ,tls key creation for remote ssh and loading of custom bash scripts to respective instances.

- Custom bash scripts to download necessary services loaded and initialized to respective instances upon instance creation.

- Selective ports allowed for ingress and egress for security hardening.

- Promtail exporting data for monitoring enstance to log.

- Internal server-to-server communication uses private VPC networking and security-group relationships where appropriate.

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
This creates 
- S3 → stores Terraform state
- DynamoDB → provides state locking

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

## Security

Security groups are separated by EC2 role:

- Jenkins SG
- Deployment SG
- Monitoring SG

Only the required ports are exposed between the servers.

Server-to-server communication uses private VPC addresses/security-group relationships where possible rather than exposing internal services to the public Internet.

Examples include:

- Jenkins → Deployment: SSH
- Jenkins → Loki: TCP 3100
- Deployment → Loki: TCP 3100
- Internet → Deployment: HTTP
- Administration → Jenkins: SSH/Jenkins UI
- Administration → Monitoring: SSH/Grafana

The deployment server's application is exposed through Nginx rather than exposing the application container port directly.

## Problems I faced during the entire project and what I did to overcome them

1. Shift Database credentials 
Initially the database accepted hard coded values for database
```bash
  const { Client } = require('pg');
var connectionString = "postgres://[username]:[password]@localhost:5432/[database name]";

const client = new Client({
    connectionString: connectionString
});
```

which got changed to `.env.DATABASEURL` to allow easy integration of environment variables

```bash
  const client = new Client({
    connectionString: process.env.DATABASE_URL
});
```
2. The app assumed the database already came equipped with required table and columns , for that one needed to log into database and create required fields .

That is handled bu `init.sql` which is mounted in the docker-compose file to set up required fields when the compose is setup first time along with a volume mount to keep the data persistent .

3. Initializing instances from terraform required 3 different instances along with their respective scripting files to downloaded their required services , initial approach of having count and 1 user data to load files proved ineffective 

That was solved by using for_each loop and locals variable with templatefile to load multiple file with their respective scripts.

4. Due to EC2 free service and no using Elastic IP , frequent change of public IP address caused problem to always frequently change the ip within the source code multiple times.

That was solved using priivate static ip which can be set free of cost to talk to each other within the same VPC for deployment and monitoring server.

5. Though nginx logs were easily accessible , jenkins logs were not . Jenkins logs are scrapped off from journalctl

6. During early testing , jenkins server used to crash when reaching deployment stage , become unresponsive , slow logging in from SSH , upon inspection it was found. 

Terraform default initialization only allocated 8GB to volumes ,hence jenkins logs gave "out of storage" error , for that all the instances were assigned 20G of memory.

```bash
  root_block_device {
    volume_size = 20
  }
```

7. Jenkins server still showed signs of freezing ,unresponsiveness during the first triggre push 

For the issue , command to allocate 2GB of swap memory within the jenkins server in `jenkins.sh` and a reboot after setup , which will cause a slight delay in server initilization. 



## License

[MIT](https://choosealicense.com/licenses/mit/)