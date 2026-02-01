pipeline {
    agent any

    environment {
        DOCKER_USERNAME = 'titi92390'
        KUBECONFIG_PATH = '/etc/rancher/k3s/k3s.yaml'
        SERVICES = 'auth users items'
    }

    stages {
        stage('1. Checkout') {
            steps {
                echo "📥 Clonage du repo..."
                git branch: 'master', url: 'https://github.com/titi92390/fastapi-microservices-sep25.git'
            }
        }

        stage('2. Build Docker Images') {
            steps {
                echo "🔨 Build des images Docker..."
                sh '''
                    for service in ${SERVICES}; do
                        echo "Building ${service}..."
                        docker build -t ${DOCKER_USERNAME}/${service}:dev ./Microservices/${service}/
                    done
                    echo "Building frontend..."
                    docker build -f ./frontend/Dockerfile.dev -t ${DOCKER_USERNAME}/frontend:dev ./frontend/
                '''
            }
        }

        stage('3. Push Docker Images') {
            steps {
                echo "📤 Push des images sur Docker Hub..."
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}
                        for service in ${SERVICES}; do
                            echo "Pushing ${service}..."
                            docker push ${DOCKER_USERNAME}/${service}:dev
                        done
                        echo "Pushing frontend..."
                        docker push ${DOCKER_USERNAME}/frontend:dev
                        docker logout
                    '''
                }
            }
        }

        stage('4. Deploy sur Kubernetes') {
            steps {
                echo "🚀 Déploiement sur k3s..."
                sh '''
                    export KUBECONFIG=${KUBECONFIG_PATH}
                    cd helm/platform
                    helm dependency update
                    helm upgrade --install platform . \
                        -f ../../overlays/dev/values.yaml \
                        -n dev \
                        --timeout 180s
                '''
            }
        }

        stage('5. Vérification') {
            steps {
                echo "✅ Vérification des pods..."
                sh '''
                    export KUBECONFIG=${KUBECONFIG_PATH}
                    kubectl get pods -n dev
                    echo "---"
                    echo "Frontend :" && curl -s -o /dev/null -w "HTTP %{http_code}\n" http://172.31.31.104:30080/
                    echo "Auth :" && curl -s -o /dev/null -w "HTTP %{http_code}\n" http://172.31.31.104:30081/health
                    echo "Users :" && curl -s -o /dev/null -w "HTTP %{http_code}\n" http://172.31.31.104:30082/docs
                    echo "Items :" && curl -s -o /dev/null -w "HTTP %{http_code}\n" http://172.31.31.104:30083/docs
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline terminé avec succès !"
        }
        failure {
            echo "❌ Pipeline échoué !"
        }
    }
}
