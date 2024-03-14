# Use the Node.js version 16 image based on Alpine Linux as the base image
FROM node:16-alpine
# Set the working directory inside the container to /app
WORKDIR /app
# Copy all files from the current directory on the host to the /app directory inside the container
COPY . ./
# Copy the Nginx configuration file from the host to the /etc/nginx/nginx.conf path inside the container
COPY nginx.conf /etc/nginx/nginx.conf
# Run the npm install command to install dependencies defined in package.json
RUN npm install
# Inform Docker that the container listens on port 8080 at runtime
EXPOSE 8080
# Install Nginx without caching to minimize the container size
RUN apk --no-cache add nginx
# Define the command to build the application and start Nginx when the container starts
ENTRYPOINT ["sh", "-c", "npm run build && nginx -g \"daemon off;\""]
