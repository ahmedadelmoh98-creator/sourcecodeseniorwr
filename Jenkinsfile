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

        EKS_CLUSTER    = 'vprofile-devops-dev-cluster'
        K8S_NAMESPACE  = 'vprofile'
        HELM_RELEASE   = 'vprofile'
        HELM_CHART     = 'vprofile-chart'
    }

    stages {

        stage('Checkout Test') {
            steps {
                echo 'Jenkins successfully loaded the Jenkinsfile from GitHub'
            }
        }

        stage('Maven Build') {
            steps {
                sh '''
                    mvn clean package -DskipTests
                '''
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

        stage('Update EKS Kubeconfig') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {
                    sh '''
                        mkdir -p ${WORKSPACE}/.kube

                        aws eks update-kubeconfig \
                        --region ${AWS_REGION} \
                        --name ${EKS_CLUSTER} \
                        --kubeconfig ${WORKSPACE}/.kube/config

                        export KUBECONFIG=${WORKSPACE}/.kube/config

                        kubectl get nodes
                    '''
                }
            }
        }

        stage('Helm Deploy to EKS') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {
                    sh '''
                        export KUBECONFIG=${WORKSPACE}/.kube/config

                        helm lint ./${HELM_CHART}

                        helm upgrade --install ${HELM_RELEASE} ./${HELM_CHART} \
                        --namespace ${K8S_NAMESPACE} \
                        --create-namespace \
                        --set image.repository=${ECR_REGISTRY}/${ECR_REPOSITORY} \
                        --set image.tag=${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Verify EKS Deployment') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {
                    sh '''
                        export KUBECONFIG=${WORKSPACE}/.kube/config

                        kubectl rollout status deployment/vprofile \
                        --namespace ${K8S_NAMESPACE} \
                        --timeout=300s

                        kubectl get pods -n ${K8S_NAMESPACE}
                        kubectl get svc -n ${K8S_NAMESPACE}
                        kubectl get ingress -n ${K8S_NAMESPACE}
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully'
            echo "Image pushed with tag: ${BUILD_NUMBER}"
            echo "ECR Image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}"
            echo "Application deployed to EKS cluster: ${EKS_CLUSTER}"
        }

        failure {
            echo 'Pipeline failed'
        }

        always {
            echo 'Pipeline execution finished'
        }
    }
}
