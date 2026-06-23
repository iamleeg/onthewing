FROM node:18-alpine

# Install Java (required for Firebase Storage Emulator) and bash
RUN apk add --no-cache openjdk11-jre bash

# Install firebase-tools globally
RUN npm install -g firebase-tools

WORKDIR /firebase

# Copy configurations
COPY firebase.json storage.rules ./

# Expose ports for Auth, Storage, and Emulator UI
EXPOSE 9099 9199 4000

# Start emulators
CMD ["firebase", "emulators:start", "--project", "onthewing-eedce"]
