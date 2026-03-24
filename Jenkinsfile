pipeline {
    agent any

    environment {
        // AWS region
        AWS_REGION = 'us-east-2'

        // Your ECR repository URIs
        FRONTEND_REPO = '776060340745.dkr.ecr.us-east-2.amazonaws.com/devops-challenge-frontend'
        BACKEND_REPO = '776060340745.dkr.ecr.us-east-2.amazonaws.com/devops-challenge-backend'
        
        // Your ECS cluster and service names
        CLUSTER_NAME = 'devops-challenge-cluster'
        FRONTEND_SERVICE = 'devops-challenge-frontend-service'
        BACKEND_SERVICE = 'devops-challenge-backend-service'
    }

    stages {
        stage('Checkout code') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker images') {
            steps {
                script {
                    sh 'docker build -t frontend:latest ./frontend'
                    sh 'docker build -t backend:latest ./backend'
                }
            }
        }

        stage('Authenticate to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    script {
                        sh '''
                            aws --version
                            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $FRONTEND_REPO
                            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $BACKEND_REPO
                        '''
                    }
                }
            }
        }

        stage('Tag and Push images to ECR') {
            steps {
                script {
                    sh '''
                        docker tag frontend:latest $FRONTEND_REPO:latest
                        docker tag backend:latest $BACKEND_REPO:latest

                        docker push $FRONTEND_REPO:latest
                        docker push $BACKEND_REPO:latest
                    '''
                }
            }
        }

        stage('Update ECS services') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    script {
                        sh '''
                            aws ecs update-service --cluster $CLUSTER_NAME --service $FRONTEND_SERVICE --force-new-deployment --region $AWS_REGION
                            aws ecs update-service --cluster $CLUSTER_NAME --service $BACKEND_SERVICE --force-new-deployment --region $AWS_REGION
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}