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
                    sh 'docker build -t manhumann/nodejs-postgres-app:${BUILD_NUMBER} .' 
                    sh 'docker tag manhumann/nodejs-postgres-app:${BUILD_NUMBER} manhumann/nodejs-postgres-app:latest'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                        docker push manhumann/nodejs-postgres-app:latest
                        docker push manhumann/nodejs-postgres-app:${BUILD_NUMBER}
                    '''
                }
            }

        stage('Deploy') {
            steps {
                sshagent(['jenkins-server-private-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@10.0.1.77 '
                            cd /opt/nodejs-postgres-app &&
                            docker compose pull &&
                            docker compose up -d
                        '
                    """
                }
            }
        }
        }
    }
}
