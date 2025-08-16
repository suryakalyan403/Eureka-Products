// This JenkinsFile is for Eureka Deployment 


pipeline {

  agent {

    label "k8s-jenkins-slave"
  
  }

  tools {

    MVN_HOME = "/opt/apache-maven-3.8.8/bin"
    PATH = "${MVN_HOME}/bin:${MVN_HOME}"

    JAVA_HOME = "/opt/jdk-17.0.2/bin"
    PATH = "${JAVA_HOME}/bin:${MVN_HOME}"


  }

  //stages
  stages {

    stage ('Build') {

       steps {

         echo " ***** Testing the Jenkins File"
         sh "nvn clean package -DskipTests=true"

      }

    }

  }

}
