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
                    sh 'docker build -t manhumann/devops-capstone:latest .'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                        docker push manhumann/devops-capstone:latest
                    '''
                }
            }
        }
    }
}
