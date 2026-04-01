FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
COPY . .
COPY ../../env/nginx/nebula/.env .env
RUN npm install
RUN npm run build

FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/dist /usr/share/nginx/html/nebula/app
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
