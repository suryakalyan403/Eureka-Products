// This JenkinsFile is for Eureka Deployment 
pipeline {
    agent {
        label "k8s-jenkins-slave"
    }

    tools {
        maven 'Maven-3.8.8'
        jdk 'JDK-17'
    }
    environment {
        APPLICATION_NAME = 'eureka'
        SONAR_TOKEN = credentials('sonar_creds')
        SONAR_URL = 'http://34.132.120.13:9000'
    }
    stages {
        stage('Build') {
            steps {
                echo "***** Testing the Jenkins File *****"
                sh "mvn clean package -DskipTests=true"
                sh "java -version"
            }
        }

        stage('Sonar') {
            steps {
                echo "Starting the Sonar scan.........."
                withSonarQubeEnv('SonarQube'){
                    sh """
                       mvn clean verify sonar:sonar \
                       -Dsonar.projectKey=test \
                       -Dsonar.host.url=${env.SONAR_URL} \
               	       -Dsonar.login=${SONAR_TOKEN}
                    """
               }
               timeout (time: 2, unit: 'MINUTES'){
                   waitForQualityGate abortPipeline: true

               }
            }
        }
    }
}

