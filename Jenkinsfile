pipeline {
  agent any

  environment {
    REGISTRY = "docker.io/titi92390"
    TAG = "dev"
    KUBE_NAMESPACE = "fastapi"
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
              docker build -t $REGISTRY/$svc:$TAG Microservices/$svc
              docker push $REGISTRY/$svc:$TAG
            done
          '''
        }
      }
    }

    stage('Deploy with Helm') {
      steps {
        sh '''
          helm dependency build helm/platform
          helm upgrade --install platform helm/platform \
            -n $KUBE_NAMESPACE \
            -f helm/platform/values.yaml \
            --create-namespace
        '''
      }
    }
  }
}
