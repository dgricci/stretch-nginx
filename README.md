% Nginx web service  
% Didier Richard  
% 2018/09/16

---

revision:
    - 1.0.0 : 2018/09/05
    - 1.0.1 : 2018/09/16 : nginx 1.10.3  

---

# First layer : web service #

The chosen web server is [Nginx](http://nginx.org) cause it is lightweight and
easy to configure.

> [wikipedia.org/wiki/Nginx](https://en.wikipedia.org/wiki/Nginx)
>
> ![logo](http://nginx.org/nginx.png)

There also is this [docker official nginx image](https://hub.docker.com/_/nginx/) worth a glance.

## Building the image ##

### Directory layout ###

```bash
$ tree .
`
.
├── Dockerfile
├── etc
│   └── nginx
│       ├── nginx.conf
│       └── sites-available
│           └── default
├── generate_sslcert.sh
├── README.md
└── var
    └── www
        └── html
            ├── 404.html
            ├── 50x.html
            └── index.html

6 directories, 8 files
```

The `default` site defines both a `HTTP` service and a `HTTPS` one. To do so,
the bash script `generate_sslcert.sh` is used to generate self-signed SSL
certificate (one year valid) in the `/etc/nginx/ssl/` image directory.
The web service root directory is `/var/www/html/`.

### Build ###

```bash
$ docker build -t dgricci/nginx:$(< VERSION) .
$ docker tag dgricci/nginx:$(< VERSION) dgricci/nginx:latest
```

### Manuel tests ###

```bash
$ docker run --name mynginx -p 6080:80 -p 6443:443 -d dgricci/nginx:$(< VERSION)
$ docker port mynginx
443/tcp -> 0.0.0.0:6443
80/tcp -> 0.0.0.0:6080
$ docker exec -ti mynginx /bin/bash
root@7d17c4baaef8:/var/www/html# ls -l
total 16
-rw-rw-r-- 1 www-data www-data 344 Apr 28  2016 404.html
-rw-rw-r-- 1 www-data www-data 357 Apr 28  2016 50x.html
-rw-rw-r-- 1 www-data www-data 371 Apr 28  2016 index.html
-rw-r--r-- 1 www-data www-data 612 Sep  5 21:30 index.nginx-debian.html
root@7d17c4baaef8:/var/www/html# exit
exit
$ wget -O containerIndex.html http://localhost:6080/
$ diff -q containerIndex.html var/www/html/index.html
$ docker logs mynginx
172.17.0.1 - - [05/Sep/2018:21:33:13 +0000] "GET / HTTP/1.1" 200 371 "-" "Wget/1.19.4 (linux-gnu)" "-"
$ wget --no-check-certificate -O containerIndex.html https://localhost:6443/
$ diff -q containerIndex.html var/www/html/index.html
$ docker logs mynginx
172.17.0.1 - - [05/Sep/2018:21:33:13 +0000] "GET / HTTP/1.1" 200 371 "-" "Wget/1.19.4 (linux-gnu)" "-"
172.17.0.1 - - [05/Sep/2018:21:33:59 +0000] "GET / HTTP/1.1" 200 371 "-" "Wget/1.19.4 (linux-gnu)" "-"
$ docker stop mynginx
mynginx
$ docker rm mynginx
mynginx
```

# How to use this image #

## hosting some simple static content ##

As the web service root directory is `/var/www/html/`, one just needs to
replace its content by another one to serve HTML pages. Link your HTML static
content to the web service root directory as follows :

```console
$ docker run --name mynginx -v /path/to/html-content:/var/www/html:ro -d dgricci/nginx:$(< VERSION)
```

Alternatively, a simple `Dockerfile` can be used to generate a new image that
includes the necessary content (which is a much cleaner solution than the bind
mount above):

```dockerfile
FROM dgricci/nginx:$(< VERSION)
COPY static-html-directory /var/www/html
```

Place this file in the same parent directory of `static-html-directory`,
launch `docker build -t my-static-content-nginx .`, then start your container :

```console
$ docker run --name another-nginx -d my-static-content-nginx
```

## exposing the port ##

This image exposes ports 80 (HTTP) and 443 (HTTPS). If you want to get access
to the web service, just map your host port to the targetted container's port
:

```console
$ docker run --name http-nginx -d -p 8080:80 my-static-content-nginx
```

Then you can hit `http://localhost:8080` or `http://your-public-host-ip:8080` in your
browser.

You can map both 80 and 443 ports :

```console
$ docker run --name http-https-nginx -d -p 8080:80 -p 8443:443 my-static-content-nginx
```

## complex configuration ##

The nginx service configuration is handled in `/etc/nginx/nginx.conf`. You can
override the image configuration easely by linking a configuration with the
one in the image :

```console
$ docker run --name some-nginx -v /some/nginx.conf:/etc/nginx/nginx.conf:ro -d nginx
```

For information on the syntax of the Nginx configuration files, see [the official documentation](http://nginx.org/en/docs/)
(specifically the [Beginner's Guide](http://nginx.org/en/docs/beginners_guide.html#conf_structure)).

## building a new image from this one ##

In case you add a new functionaly layer (e.g., by adding a new service), be
sure to include `daemon off;` either in your custom configuration to ensure that
Nginx stays in the foreground so that Docker can track the process properly
(otherwise your container will stop immediately after starting) or in the
`CMD` instruction !

# TODO #

Use [Let's encrypt](https://letsencrypt.org/) : [Certbot](https://github.com/certbot/certbot)  
See [Using letsencrypt with nginx on docker](https://blog.nbellocam.me/2016/03/10/letsencrypt-and-nginx-on-docker/)

