# Use the official Node.js image as the base image
FROM node:18-alpine

# Set the working directory
WORKDIR /app



# Copy entry script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh


# List the contents of /app to verify
RUN ls -la /app


# Expose the port the app runs on
EXPOSE 3001

# Set the entrypoint
ENTRYPOINT ["sh", "/app/entrypoint.sh"]

