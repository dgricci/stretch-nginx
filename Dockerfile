# Dockerfile for Nginx
FROM dgricci/stretch:1.0.0
MAINTAINER Didier Richard <didier.richard@ign.fr>
LABEL       version="1.0.0" \
            nginx="1.11" \
            os="Debian Stretch" \
            description="NGinx web server"

# copy nginx configuration :
COPY etc/nginx/nginx.conf /tmp/nginx.conf
COPY etc/nginx/sites-available/default /tmp/default

# if <dest> ends with a trailing slash /, it will be considered a directory and the contents of <src> will be written at <dest>/base(<src>)
# if <dest> doesn’t exist, it is created along with all missing directories in its path.
COPY var/www/html/* /var/www/html/

# set up self-signed SSL certificate for a year
COPY generate_sslcert.sh /tmp/generate_sslcert.sh

COPY build.sh /tmp/build.sh
RUN /tmp/build.sh && rm -f /tmp/build.sh
WORKDIR /var/www/html/

# listen to port 80 and 443 of this container
EXPOSE 80 443
# to ensure that nginx stays in the foreground so that Docker can track the
# process properly (otherwise your container will stop immediately after
# starting)!
CMD ["nginx", "-g", "daemon off;"]

