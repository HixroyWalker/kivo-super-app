FROM node:20-alpine

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./
RUN npm install --only=production

# Bundle app source
COPY . .

# Cloud Run enforces a PORT environment variable, defaults to 8080
ENV PORT=8080
EXPOSE 8080

# Start the Node.js Express server
CMD [ "npm", "start" ]
