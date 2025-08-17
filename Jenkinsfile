// This JenkinsFile is for Eureka Deployment 

pipeline {
  agent {
    label "k8s-jenkins-slave"
  }

  tools {

    maven 'Maven-3.8.8'
    jdk 'JDK-17'

  }

  //environment {
  //  MVN_HOME = "/opt/apache-maven-3.8.8"
  //  JAVA_HOME = "/opt/jdk-17.0.2"
  //PATH = "${MVN_HOME}/bin:${JAVA_HOME}/bin:${PATH}"
  // }

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
        mvn clean verify sonar: sonar\ -
          Dsonar.projectKey = test\ -
          Dsonar.host.url = http: //34.44.215.147:9000 \
          -Dsonar.login = squ_d5e96b0ef5388b80cbfb834f12ac1ece5c47032e

      }

    }

  }

}
