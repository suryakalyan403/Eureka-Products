pipeline {
    agent {
        // Jenkins will run this pipeline on a node/agent with this label
        label "k8s-jenkins-slave"
    }

    tools {
        // Pre-installed Maven and JDK to use
        maven 'Maven-3.8.8'
        jdk 'JDK-17'
    }

    environment {
        // Application Info
        APPLICATION_NAME = 'eureka'

        // SonarQube Credentials & URL
        SONAR_TOKEN = credentials('sonar_creds')
        SONAR_IP    = "34.23.178.132"
        SONAR_PORT  = "9000"
        SONAR_URL   = "http://${SONAR_IP}:${SONAR_PORT}"

        // Read Maven project metadata
        POM_VERSION   = readMavenPom().getVersion()
        POM_PACKAGING = readMavenPom().getPackaging()

        // Docker Info
        DOCKER_HUB  = "docker.io/7981689475"
        DOCKER_CREDS = credentials('docker_creds') // Registry creds
    }

    stages {

        // ---------------- BUILD STAGE ----------------
        stage('Build') {
            steps {
                echo "***** Starting the Build Stage *****"
                sh "hostname -i"
                sh "mvn clean package -DskipTests=true"
                sh "java -version"
            }
        }

        // ---------------- SONARQUBE SCAN ----------------
        stage('Sonar') {
            steps {
                echo "***** Starting the SonarQube Scan *****"
                withSonarQubeEnv('SonarQube') {
                    sh """
                        mvn clean verify sonar:sonar \
                          -Dsonar.projectKey=${env.APPLICATION_NAME} \
                          -Dsonar.host.url=${SONAR_URL} \
                          -Dsonar.login=${SONAR_TOKEN}
                    """
                }

                // Wait for Quality Gate result (max 10 minutes)
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        // ---------------- DOCKER BUILD & PUSH ----------------
        stage('Docker Build') {
            steps {
                echo "***** Starting Docker Build Stage *****"
                echo "JAR Destination: ${env.APPLICATION_NAME}-${BUILD_NUMBER}-${BRANCH_NAME}.${env.POM_PACKAGING}"
                 
                def jarSource = ${env.APPLICATION_NAME}-${env.POM_VERSION}.${env.POM_PACKAGING}
                def imageName = ${env.DOCKER_HUB}/${env.APPLICATION_NAME}:${GIT_COMMIT}

                echo "JAR Source: ${jarSource}"
                echo "IMAGE NAME: ${imageName}"

                # Copy the JAR into Docker build context
                cp ${WORKSPACE}/target/${jarSource} ${jarSource}

                dockerBuildPush(jarSource, imageName).call()
                

            }
        }

        // ---------------- DEPLOY TO DEV ----------------
        stage('Deploy to Dev') {
            steps {
                echo "***** Deploying to Dev Server *****"

                withCredentials([usernamePassword(
                    credentialsId: 'docker_server_creds',
                    usernameVariable: 'USERNAME',
                    passwordVariable: 'PASSWORD'
                )]) {

                    script {

                      def applicationName = ${APPLICATION_NAME}-dev
                      def imageName = ${env.DOCKER_HUB}/${env.APPLICATION_NAME}:${GIT_COMMIT}
                      def hostPort = "5761"
                      def containerPort = "8761"
                       
                      dockerDeploy(applicationName, imageName, hostPort, containerPort).call()
                     
                    }
                }
            }
        }
    }
}



def dockerBuildPush(jarsource,imagename) {
    return {
        sh """
            echo "********************** Building Docker Image **********************"

            # Build the Docker image
            docker build --no-cache \
              --build-arg JAR_SOURCE=target/${jarsource} \
              -t ${imagename} .

            echo "******************** Login to Docker Registry **********************"
            docker login -u ${DOCKER_CREDS_USR} -p ${DOCKER_CREDS_PSW}

            # Push the image
            docker push ${imagename}
        """
    }
}


def dockerDeploy(applicationName, imageName,hostPort, containerPort) {
    return {
        // Pull the latest image
        sh '''
            sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USERNAME@$DOCKER_IP \
            "docker pull ${imageName}"
        '''

        try {
            // Stop the running container if it exists
            sh '''
                sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USERNAME@$DOCKER_IP \
                "docker stop ${imageName} || true"
            '''

            // Remove the container if it exists
            sh '''
                sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USERNAME@$DOCKER_IP \
                "docker rm ${imageName} || true"
            '''
        } catch (err) {
            echo "Error caught during cleanup: $err"
        }

        // Run a fresh container
        sh '''
            sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USERNAME@$DOCKER_IP \
            "docker run -dit --name ${applicationName} -p ${hostPort}:${containerPort} ${imageName}"
        '''
    }
}

