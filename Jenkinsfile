pipeline {
    agent any

    tools {
        jdk 'JDK17'
        maven 'Maven3'
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

        stage('Docker Build') {
            steps {
                sh 'docker build -t vprofile-app:latest .'
            }
        }

        stage('Trivy Scan') {
            steps {
                sh '''
                    trivy image \
                    --timeout 15m \
                    --severity HIGH,CRITICAL \
                    --exit-code 0 \
                    vprofile-app:latest
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully'
        }

        failure {
            echo 'Pipeline failed'
        }

        always {
            echo 'Pipeline execution finished'
        }
    }
}
