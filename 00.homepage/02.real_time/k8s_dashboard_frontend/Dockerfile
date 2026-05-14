# ─────────────────────────────────────────────────────────────
# Stage 1: Build Angular
# ─────────────────────────────────────────────────────────────
FROM node:22-alpine AS builder

WORKDIR /build

# Copy package files and install dependencies
COPY package*.json ./
RUN npm ci --silent

# Copy source and build for production
COPY . .
RUN npm run build:prod

# ─────────────────────────────────────────────────────────────
# Stage 2: Serve with NGINX (ARM64 compatible)
# ─────────────────────────────────────────────────────────────
FROM nginx:1.27-alpine

LABEL maintainer="AdailSilva <adail101@hotmail.com>"
LABEL org.opencontainers.image.title="k8s-dashboard-frontend"
LABEL org.opencontainers.image.description="Kubernetes Dashboard - Angular Frontend"

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy built Angular app
COPY --from=builder /build/dist/k8s-dashboard-frontend/browser /usr/share/nginx/html

# Custom nginx config with Angular routing support + API proxy
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
