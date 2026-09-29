pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm

            }
        }

        stage('Install Dependencies') {
            steps {
                dir('CRUD-Nodejs-PostgreSQL') {
                    sh 'npm ci'
                }
            }
        }

        stage('Test') {
            steps {
                dir('CRUD-Nodejs-PostgreSQL') {
                    sh 'npm test'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('CRUD-Nodejs-PostgreSQL') {
                    sh 'docker build -t manhumann/nodejs-postgres-app:latest .' 
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-hub-access-token',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                        docker push manhumann/nodejs-postgres-app:latest

                    '''
                     
                }
            }
        }
        
        stage('Deploy') {
            steps {
                 
                sshagent(['jenkins-server-private-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@10.0.1.8 '               
                            cd /opt/nodejs-postgres-app &&
                            docker compose pull &&
                            docker compose up -d
                        '
                    '''
                }
            }
        }
        
    }
}
