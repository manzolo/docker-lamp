# docker-lamp

```bash
git clone https://github.com/manzolo/docker-lamp.git
cd docker-lamp/
docker build -t manzolo/docker-lamp .
```
##Enter shell
```bash
docker run -it manzolo/docker-lamp /bin/bash
```
##Launch web server
```bash
docker run -d -p 8080:80 -p 33060:3306 manzolo/docker-lamp
```
##Navigate to
```
http://localhost:8080
```
##Navigate to phpmyadmin (user: "root" , empty password)
```
http://localhost:8080/phpmyadmin
```
