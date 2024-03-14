# Use the OpenJDK 17 image based on Alpine Linux as the base image
FROM openjdk:17-jdk-alpine
# Set the maintainer label with your email address
#MAINTAINER yourname@example.com
# Copy the compiled JAR file from the target directory on the host to the /app.jar path inside the container
COPY target/your-spring-boot-app-1.0.0.jar /app.jar
# Inform Docker that the container listens on port 9191 at runtime
EXPOSE 9191
# Define the command to run the application when the container starts
ENTRYPOINT ["java", "-jar", "/app.jar"]
