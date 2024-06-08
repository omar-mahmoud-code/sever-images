#!/bin/bash


# cd /app
cd /app


# ls -la /app
ls -la /app

# Install dependencies
yarn install

# Build the Next.js application
yarn build

# Run the Next.js production server
yarn start
