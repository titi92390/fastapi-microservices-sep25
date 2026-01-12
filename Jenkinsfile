pipeline {
  agent any

  environment {
    REGISTRY = "docker.io/titi92390"
    TAG = "dev"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Docker Build & Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {

          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

            SERVICES="auth users items frontend"

            for svc in $SERVICES; do
              echo "Building $svc"
              docker build -t $REGISTRY/$svc:$TAG Microservices/$svc
              docker push $REGISTRY/$svc:$TAG
            done
          '''
        }
      }
    }
  }
}
