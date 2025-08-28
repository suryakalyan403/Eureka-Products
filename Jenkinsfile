// This JenkinsFile is for Eureka Deployment 
// This JenkinsFile is for Eureka Deployment
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
        SONAR_TOKEN      = credentials('sonar_creds')
        SONAR_URL        = 'http://35.188.83.190:9000'
        // Make sure pipeline-utility-steps plugin installed in the jenkins server, if you are using readMaven packages
        // Wehave to provide neccessary approvals
        POM_VERSION = readMavenPom().getVersion()
        POM_PACKAGING = readMavenPom().getPackaging()

        //Docker Info
        DOCKER_HUB = "docker.io/7981689475"
        
        // Docker Username and Password
        DOCKER_CREDS = credentials('docker_creds')
        
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
                withSonarQubeEnv('SonarQube') {
                    sh """
                        mvn clean verify sonar:sonar \
                          -Dsonar.projectKey=test \
                          -Dsonar.host.url=${env.SONAR_URL} \
                          -Dsonar.login=${SONAR_TOKEN}
                    """
                }
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                echo "Currently in the docker stage"
                echo "My JAR Source:  ${env.APPLICATION_NAME}-${env.POM_VERSION}.${env.POM_PACKAGING}"
                echo "My JAR Destination: ${env.APPLICATION_NAME}-${BUILD_NUMBER}-${BRANCH_NAME}.${env.POM_PACKAGING}"


                sh """
                   echo "********************** Buliding Docker Image **********************"
                   cp ${WORKSPACE}/target/${env.APPLICATION_NAME}-${env.POM_VERSION}.${env.POM_PACKAGING} ${env.APPLICATION_NAME}-${env.POM_VERSION}.${env.POM_PACKAGING}
                   docker build --no-cache \
                    --build-arg JAR_SOURCE=target/${env.APPLICATION_NAME}-${env.POM_VERSION}.${env.POM_PACKAGING} \
                    -t ${env.DOCKER_HUB}/${env.APPLICATION_NAME}:${GIT_COMMIT} \
                    .
                   echo "******************** Login to the Docker Registry  **********************"
                   docker login -u ${DOCKER_CREDS_USR} -p ${DOCKER_CREDS_PSW}

                   docker push ${env.DOCKER_HUB}/${env.APPLICATION_NAME}:${GIT_COMMIT}
                """

            }
        }

       stage ('Deploy to Dev') {

          steps {
             
             echo "Deploying to Dev Server"
             withCredentials([usernamePassword(credentialsId: 'docker_server_creds', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {

                sh "sshpass -p '$PASSWORD' -v ssh -o StrictHostKeyChecking=no $USERNAME@$docker_server \'hostname -i'"

              }

              // create a container
              // docker container create imagename
              docker run -dit --name ${env.APPLICATION_NAME}-dev 5761:8761 ${env.DOCKER_HUB}/${env.DOCKER_HUB}/${env.APPLICATION_NAME}:${GIT_COMMIT}
              

           }

       }

    }
}

// Eureka
// Container Port 8761

// dev hp: 5761
// tst hp: 6761
// stg hp: 7761
// prod hp: 8761 
