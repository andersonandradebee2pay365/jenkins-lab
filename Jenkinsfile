pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo 'Clonando repositório...'
            }
        }

        stage('Build') {
            steps {
                echo 'Instalando dependências...'
                bat 'pip install -r requirements.txt'
            }
        }

        stage('Test') {
            steps {
                echo 'Executando testes...'
                bat 'pytest'
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Build da imagem Docker...'
                bat 'docker build -t jenkins-lab-app .'
            }
        }
    }
}