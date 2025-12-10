# --- Builder stage ---
FROM node:18-slim AS builder

WORKDIR /app

# Copier les fichiers de dépendances
COPY package.json package-lock.json ./

# Installer les dépendances
RUN npm install

# Copier tout le code
COPY . .

# Build Next.js
RUN npm run build

# --- Runner stage ---
FROM node:18-slim AS runner

WORKDIR /app

ENV NODE_ENV=production

# Copier uniquement ce qui est nécessaire
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules

EXPOSE 3000

CMD ["npm", "start"]
