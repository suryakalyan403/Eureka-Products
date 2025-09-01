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

        // SonarQube
        SONAR_TOKEN = credentials('sonar_creds')
        SONAR_URL   = "http://${SONAR_IP}:${SONAR_PORT}"

        // Maven POM
        POM_VERSION   = readMavenPom().getVersion()
        POM_PACKAGING = readMavenPom().getPackaging()

        // Docker
        DOCKER_HUB  = "docker.io/7981689475"
        DOCKER_CREDS = credentials('docker_creds')
    }

    stages {

        stage('Build') {
            steps {
                echo "***** Starting the Build Stage *****"
                sh "hostname -i"
                sh "mvn clean package -DskipTests=true"
                sh "java -version"
            }
        }

        stage('Sonar') {
            steps {
                echo "***** Starting the SonarQube Scan *****"
                withSonarQubeEnv('SonarQube') {
                    sh """
                        mvn clean verify sonar:sonar \
                          -Dsonar.projectKey=${env.APPLICATION_NAME} \
                          -Dsonar.host.url=${env.SONAR_URL} \
                          -Dsonar.login=${env.SONAR_TOKEN}
                    """
                }

                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    echo "***** Starting Docker Build Stage *****"

                    def jarSource = "${APPLICATION_NAME}-${POM_VERSION}.${POM_PACKAGING}"
                    def imageName = "${DOCKER_HUB}/${APPLICATION_NAME}:${GIT_COMMIT}"

                    echo "JAR Source: ${jarSource}"
                    echo "Image Name: ${imageName}"

                    sh "cp ${WORKSPACE}/target/${jarSource} ${jarSource}"

                    dockerBuildPush(jarSource, imageName)
                }
            }
        }

        stage('Deploy to Dev') {
            steps {
                echo "***** Deploying to Dev Server *****"
                withCredentials([usernamePassword(
                    credentialsId: 'docker_server_creds',
                    usernameVariable: 'USERNAME',
                    passwordVariable: 'PASSWORD'
                )]) {
                    script {
                        def applicationName = "${APPLICATION_NAME}-dev"
                        def imageName = "${DOCKER_HUB}/${APPLICATION_NAME}:${GIT_COMMIT}"
                        def hostPort = "5761"
                        def containerPort = "8761"

                        dockerDeploy(applicationName, imageName, hostPort, containerPort)
                    }
                }
            }
        }
    }
}

// --------- Functions ---------
def dockerBuildPush(jarSource, imageName) {
    sh """
        echo "********************** Building Docker Image **********************"

        docker build --no-cache \
          --build-arg JAR_SOURCE=${jarSource} \
          -t ${imageName} .

        echo "******************** Login to Docker Registry **********************"
        docker login -u ${DOCKER_CREDS_USR} -p ${DOCKER_CREDS_PSW}

        docker push ${imageName}
    """
}

def dockerDeploy(applicationName, imageName, hostPort, containerPort) {
    sh """
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USERNAME@$DOCKER_IP \
        "docker pull ${imageName}"
    """

    try {
        sh """
            sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USERNAME@$DOCKER_IP \
            "docker stop ${applicationName} || true && docker rm ${applicationName} || true"
        """
    } catch (err) {
        echo "Error caught during cleanup: ${err}"
    }

    sh """
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USERNAME@$DOCKER_IP \
        "docker run -dit --name ${applicationName} -p ${hostPort}:${containerPort} ${imageName}"
    """
}

