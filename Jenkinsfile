pipeline {
    agent any

    environment {
        APP_NAME        = 'jenkins-lab-app'
        IMAGE_TAG       = "${env.BUILD_NUMBER}"
        IMAGE_NAME      = "${APP_NAME}:${IMAGE_TAG}"
        LATEST_IMAGE    = "${APP_NAME}:latest"
        TRIVY_SEVERITY  = 'CRITICAL,HIGH'
        TRIVY_EXIT_CODE = '1'
        REPORT_FILE     = 'trivy-report.txt'
        PUSH_IMAGE      = "${env.PUSH_IMAGE ?: 'false'}"
        REGISTRY_URL    = "${env.REGISTRY_URL ?: ''}"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Baixando código do repositório...'
                checkout scm
            }
        }

        stage('Sanity Check') {
            steps {
                echo 'Validando arquivos obrigatórios...'
                sh '''
                    set -eu
                    test -f Dockerfile
                    test -f Jenkinsfile
                    ls -lah
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Construindo imagem Docker da aplicação...'
                sh '''
                    set -eu
                    docker version
                    docker build -t "${IMAGE_NAME}" -t "${LATEST_IMAGE}" .
                    docker images | grep "${APP_NAME}" || true
                '''
            }
        }

        stage('Trivy Scan - Report') {
            steps {
                echo 'Executando varredura Trivy e gerando relatório...'
                sh '''
                    set -eu
                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      -v "$PWD:/workspace" \
                      ghcr.io/aquasecurity/trivy:latest image \
                      --no-progress \
                      --severity "${TRIVY_SEVERITY}" \
                      --format table \
                      -o "/workspace/${REPORT_FILE}" \
                      "${IMAGE_NAME}"
                '''
            }
        }

        stage('Security Gate') {
            steps {
                echo 'Aplicando gate de segurança com Trivy...'
                sh '''
                    set -eu
                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      ghcr.io/aquasecurity/trivy:latest image \
                      --no-progress \
                      --severity "${TRIVY_SEVERITY}" \
                      --exit-code "${TRIVY_EXIT_CODE}" \
                      "${IMAGE_NAME}"
                '''
            }
        }

        stage('Push Image') {
            when {
                expression {
                    return env.PUSH_IMAGE == 'true' && env.REGISTRY_URL?.trim()
                }
            }
            steps {
                echo 'Enviando imagem para registry...'
                sh '''
                    set -eu
                    docker tag "${IMAGE_NAME}" "${REGISTRY_URL}/${APP_NAME}:${IMAGE_TAG}"
                    docker tag "${IMAGE_NAME}" "${REGISTRY_URL}/${APP_NAME}:latest"
                    docker push "${REGISTRY_URL}/${APP_NAME}:${IMAGE_TAG}"
                    docker push "${REGISTRY_URL}/${APP_NAME}:latest"
                '''
            }
        }
    }

    post {
        always {
            echo 'Arquivando relatório do Trivy...'
            archiveArtifacts artifacts: "${REPORT_FILE}", fingerprint: true, onlyIfSuccessful: false, allowEmptyArchive: true

            echo 'Limpando imagens locais do build...'
            sh '''
                set +e
                docker rmi "${IMAGE_NAME}" "${LATEST_IMAGE}"
                docker image prune -f
                exit 0
            '''
        }

        success {
            echo 'Pipeline concluído com sucesso e security gate aprovado.'
        }

        failure {
            echo 'Pipeline falhou. Verifique o Console Output e o relatório do Trivy.'
        }
    }
}