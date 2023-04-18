FROM nginx

# Install dependencies
 RUN apt-get update && apt-get upgrade -y

# Install apache and write hello world message
ADD Pagefolder /usr/share/nginx/html

#port of the container 
EXPOSE 80

#runs nginx in foreground |run in background is just "nginx"
CMD ["nginx", "-g", "daemon off;"]
