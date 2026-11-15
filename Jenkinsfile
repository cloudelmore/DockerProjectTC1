pipeline {
    agent any

    environment {
        AWS_REGION       = 'us-east-1'
        REGISTRY         = '035074950748.dkr.ecr.us-east-1.amazonaws.com'
        FRONTEND_REPO    = "${REGISTRY}/tc1-frontend"
        BACKEND_REPO     = "${REGISTRY}/tc1-backend"
        CLUSTER          = 'tc1-cluster'
        FRONTEND_SERVICE = 'tc1-frontend-service'
        BACKEND_SERVICE  = 'tc1-backend-service'
        IMAGE_TAG        = "${env.BUILD_NUMBER}"
    }

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build images') {
            steps {
                sh '''
                    docker build -t $BACKEND_REPO:$IMAGE_TAG -t $BACKEND_REPO:latest ./backend
                    docker build --build-arg REACT_APP_API_URL=/api/ \
                        -t $FRONTEND_REPO:$IMAGE_TAG -t $FRONTEND_REPO:latest ./frontend
                '''
            }
        }

        stage('Log in to ECR') {
            steps {
                // Uses the EC2 instance's IAM role; no stored AWS keys
                sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY'
            }
        }

        stage('Push images') {
            steps {
                sh '''
                    docker push $BACKEND_REPO:$IMAGE_TAG
                    docker push $BACKEND_REPO:latest
                    docker push $FRONTEND_REPO:$IMAGE_TAG
                    docker push $FRONTEND_REPO:latest
                '''
            }
        }

        stage('Deploy to ECS') {
            steps {
                sh '''
                    aws ecs update-service --cluster $CLUSTER --service $BACKEND_SERVICE \
                        --force-new-deployment --region $AWS_REGION --query "service.serviceName" --output text
                    aws ecs update-service --cluster $CLUSTER --service $FRONTEND_SERVICE \
                        --force-new-deployment --region $AWS_REGION --query "service.serviceName" --output text
                '''
            }
        }

        stage('Wait for services to stabilize') {
            steps {
                sh 'aws ecs wait services-stable --cluster $CLUSTER --services $BACKEND_SERVICE $FRONTEND_SERVICE --region $AWS_REGION'
            }
        }
    }

    post {
        always {
            // Remove old local images so the Jenkins server's disk doesn't fill up
            sh 'docker image prune -f || true'
        }
        success {
            echo "Deployed build ${env.BUILD_NUMBER} to ECS."
        }
        failure {
            echo "Build ${env.BUILD_NUMBER} failed. Check the stage that turned red."
        }
    }
}