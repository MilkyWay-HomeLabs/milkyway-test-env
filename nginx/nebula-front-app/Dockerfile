# Build stage
FROM node:20-alpine AS build
WORKDIR /app
ENV CI=true
COPY package.json package-lock.json* yarn.lock* ./
RUN if [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci; \
    else npm install; fi
COPY nebula .
RUN if [ -f yarn.lock ]; then yarn build; \
    else npm run build; fi

# Runtime stage
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
