# Use the official Node.js image as the base image
FROM node:18-alpine

# Set the working directory
WORKDIR /app

# Expose the port the app runs on
EXPOSE 3001

# Copy entry script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

 
# Set the entrypoint
ENTRYPOINT ["sh", "/app/entrypoint.sh"]

