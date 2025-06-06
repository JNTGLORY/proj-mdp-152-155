FROM maven:3.9.5-eclipse-temurin-17 AS build
# Set the working directory in the container
WORKDIR /app
# Copy the pom.xml and source code to the container
COPY . .
# Build the application using Maven
RUN mvn clean package


# Deploy the application to Tomcat
FROM tomcat:9.0.104-jdk8-temurin-jammy
# Remove the default web applications
RUN rm -rf /usr/local/tomcat/webapps/*
# Copy the WAR file from the build stage to the Tomcat webapps directory
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

# Expose the port on which Tomcat will run
EXPOSE 8080 
# Start Tomcat when the container runs
CMD ["catalina.sh", "run"]