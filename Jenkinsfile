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

    stage('Docker Build') {
        steps {
            sh 'docker build -t vprofile-app:latest .'
        }
    }
}
