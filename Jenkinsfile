pipeline {
    agent any

    tools {
        jdk 'JDK17'
        maven 'Maven3'
    }

    environment {
        AWS_REGION     = 'us-east-1'
        ECR_REGISTRY   = '506715795182.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPOSITORY = 'vprofile-app'
        LOCAL_IMAGE    = 'vprofile-app:latest'
    }

    stages {

        stage('Checkout Test') {
            steps {
                echo 'Jenkins successfully loaded the Jenkinsfile from GitHub'
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.11.0.3922:sonar \
                        -Dsonar.projectKey=vprofile \
                        -Dsonar.projectName=vprofile
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t ${LOCAL_IMAGE} .
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                sh '''
                    trivy image \
                    --timeout 15m \
                    --severity HIGH,CRITICAL \
                    --exit-code 0 \
                    ${LOCAL_IMAGE}
                '''
            }
        }

        stage('Login to Amazon ECR') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {
                    sh '''
                        aws ecr get-login-password \
                        --region ${AWS_REGION} |
                        docker login \
                        --username AWS \
                        --password-stdin ${ECR_REGISTRY}
                    '''
                }
            }
        }

        stage('Tag Docker Image') {
            steps {
                sh '''
                    docker tag ${LOCAL_IMAGE} \
                    ${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}

                    docker tag ${LOCAL_IMAGE} \
                    ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                '''
            }
        }

        stage('Push Image to Amazon ECR') {
            steps {
                sh '''
                    docker push \
                    ${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}

                    docker push \
                    ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                '''
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully"
            echo "Image pushed with tag: ${BUILD_NUMBER}"
            echo "ECR Image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}"
        }

        failure {
            echo 'Pipeline failed'
        }

        always {
            echo 'Pipeline execution finished'
        }
    }
}
