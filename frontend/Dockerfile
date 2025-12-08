# Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* .npmrc* ./
RUN npm ci || npm install
COPY . .
RUN npm run build

# Runtime
FROM node:18-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY --from=builder /app ./

# Créer le dossier public s'il n'existe pas
RUN mkdir -p /app/public

# Config runtime (sans /auth /users /items)
ARG API_BASE=http://108.130.254.203
RUN echo "window.APP_CONFIG={API_AUTH:'${API_BASE}:30081/api/v1',API_USERS:'${API_BASE}:30082/api/v1',API_ITEMS:'${API_BASE}:30083/api/v1'};" > /app/public/config.js

EXPOSE 3000
CMD ["npm", "start"]