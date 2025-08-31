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
                echo "JAR Source: ${env.APPLICATION_NAME}-${env.POM_VERSION}.${env.POM_PACKAGING}"
                echo "JAR Destination: ${env.APPLICATION_NAME}-${BUILD_NUMBER}-${BRANCH_NAME}.${env.POM_PACKAGING}"

                sh """
                   echo "********************** Building Docker Image **********************"

                   # Copy the JAR for docker build context
                   cp ${WORKSPACE}/target/${env.APPLICATION_NAME}-${env.POM_VERSION}.${env.POM_PACKAGING} \
                      ${env.APPLICATION_NAME}-${env.POM_VERSION}.${env.POM_PACKAGING}

                   # Build the Docker image
                   docker build --no-cache \
                       --build-arg JAR_SOURCE=target/${env.APPLICATION_NAME}-${env.POM_VERSION}.${env.POM_PACKAGING} \
                       -t ${env.DOCKER_HUB}/${env.APPLICATION_NAME}:${GIT_COMMIT} .

                   echo "******************** Login to Docker Registry **********************"
                   docker login -u ${DOCKER_CREDS_USR} -p ${DOCKER_CREDS_PSW}

                   # Push the image
                   docker push ${env.DOCKER_HUB}/${env.APPLICATION_NAME}:${GIT_COMMIT}
                """
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
                        // Pull the latest image
                        sh '''
                            sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USERNAME@$DOCKER_IP \
                            "docker pull ${DOCKER_HUB}/${APPLICATION_NAME}:${GIT_COMMIT}"
                        '''

                        try {
                            // Stop the running container if exists
                            sh '''
                                sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USERNAME@$DOCKER_IP \
                                "docker stop ${APPLICATION_NAME}-dev || true"
                            '''

                            // Remove the container if exists
                            sh '''
                                sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USERNAME@$DOCKER_IP \
                                "docker rm ${APPLICATION_NAME}-dev || true"
                            '''
                        } catch (err) {
                            echo "Error caught during cleanup: $err"
                        }

                        // Run a fresh container
                        sh '''
                            sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USERNAME@$DOCKER_IP \
                            "docker run -dit --name ${APPLICATION_NAME}-dev -p 5761:8761 ${DOCKER_HUB}/${APPLICATION_NAME}:${GIT_COMMIT}"
                        '''
                    }
                }
            }
        }
    }
}

