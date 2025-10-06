# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

# Want to help us make this template better? Share your feedback here: https://forms.gle/ybq9Krt8jtBL3iCk7

ARG NODE_VERSION=20.9.0                         

# Use an official Node runtime as a parent image
# See https://hub.docker.com/_/node for all available tags.
# The alpine variant is a smaller image that is well-suited to production environments.
# For more information, see https://alpinelinux.org/.
# This image is used as the base for both development and production stages.
# To create a multi-stage build, we name this stage "base" so it can be referenced by other stages. 
FROM node:${NODE_VERSION}-alpine as base

# Use production node environment by default.
# This can be overridden at runtime by setting the NODE_ENV environment variable.
WORKDIR /usr/src/app

EXPOSE 3000

FROM base as dev
# Use development node environment.
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --include=dev
# Run the application as a non-root user.
USER node
# Copy the rest of the source files into the image.
COPY . .
# Expose the port that the application listens on.
CMD npm run dev


FROM base as prod

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.npm to speed up subsequent builds.
# Leverage a bind mounts to package.json and package-lock.json to avoid having to copy them into
# into this layer.  
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev


# Run the application as a non-root user.   
USER node

# Copy the rest of the source files into the image. 
COPY . .
# Expose the port that the application listens on.
CMD node src/index.js


FROM base as test
ENV NODE_ENV test
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --include=dev

# Run the application as a non-root user.  
USER node

# Copy the rest of the source files into the image.
COPY . .

# Expose the port that the application listens on.
# Run the tests.    
RUN npm run test


# Old Dockerfile content, kept for reference.

# FROM node:${NODE_VERSION}-alpine

# # Use production node environment by default.
# ENV NODE_ENV production


# WORKDIR /usr/src/app

# # Download dependencies as a separate step to take advantage of Docker's caching.
# # Leverage a cache mount to /root/.npm to speed up subsequent builds.
# # Leverage a bind mounts to package.json and package-lock.json to avoid having to copy them into
# # into this layer.
# RUN --mount=type=bind,source=package.json,target=package.json \
#     --mount=type=bind,source=package-lock.json,target=package-lock.json \
#     --mount=type=cache,target=/root/.npm \
#     npm ci --omit=dev

# # Run the application as a non-root user.
# USER node

# # Copy the rest of the source files into the image.
# COPY . .

# # Expose the port that the application listens on.
# EXPOSE 3000

# # Run the application.
# CMD node src/index.js
