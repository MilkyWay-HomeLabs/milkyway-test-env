FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY dist /usr/share/nginx/html/nebula/app
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
