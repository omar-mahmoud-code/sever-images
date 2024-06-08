# Use the official Node.js image as the base image
FROM node:20-alpine

# Set the working directory
WORKDIR /app



# Copy entry script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# List the contents of /app to verify
RUN ls -la /app


# Expose the port the app runs on
EXPOSE 3001

# Set entrypoint
ENTRYPOINT ["/bin/sh", "/usr/local/bin/entrypoint.sh"]
