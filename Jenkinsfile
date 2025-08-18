// This JenkinsFile is for Eureka Deployment 
pipeline {
    agent {
        label "k8s-jenkins-slave"
    }

    tools {
        maven 'Maven-3.8.8'
        jdk 'JDK-17'
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
                sh """
                    mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=test \
                        -Dsonar.host.url=http://34.132.120.13:9000 \
                        -Dsonar.login=squ_d5e96b0ef5388b80cbfb834f12ac1ece5c47032e
                """
            }
        }
    }
}

