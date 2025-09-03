FROM openjdk:18

#Create the Directory
RUN mkdir -p /opt/eureka-products

#Setting the working directory to /opt/eureka
WORKDIR /opt/eureka-products

#Define Build Time Variables called jar_file to specify the location of the jar file
ARG JAR_SOURCE

#Copy the Jarfile 
COPY ["${JAR_SOURCE}","/opt/eureka/eureka-products.jar"]

#Grant RWX perimissions for this directory
RUN chmod 777 /opt/eureka-products/

#Expoase port to port 8761 to allow external access to application
EXPOSE 8761

#Specify the cmd to run the Spring Based application using the JAVA JAR File
CMD ["java", "-jar", "/opt/eureka/eureka-products.jar"]
