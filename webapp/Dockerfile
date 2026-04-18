FROM node:18-alpine

WORKDIR /app

# Copy only package files first (for caching)
COPY package.json  ./

RUN npm install --only=production

# Then copy rest of code
COPY . .

EXPOSE 3000

CMD ["node", "app.js"]