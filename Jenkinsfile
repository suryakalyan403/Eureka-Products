// This JenkinsFile is for Eureka Deployment 

pipeline {
  agent {
    label "k8s-jenkins-slave"
  }

  tools {
  
    maven 'Maven-3.8.8'
    java  'JDK-17'

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
        sh "mvn -version"
        sh "java -version"
      }
    }
  }
}

