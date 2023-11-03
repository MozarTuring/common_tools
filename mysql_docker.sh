mkdir -p /home/maojingwei/mysql/config /home/maojingwei/mysql/data

echo "[mysqld]
user=mysql
character-set-server=utf8
default_authentication_plugin=mysql_native_password
 
[client]
default-character-set=utf8
 
[mysql]
default-character-set=utf8" > /home/maojingwei/mysql/config/my.conf


docker run -d -p 31004:3306 --restart always --privileged=true -e MYSQL_ROOT_PASSWORD=9213@fCOW -v /home/maojingwei/mysql/config/my.conf:/etc/my.cof -v=/home/maojingwei/mysql/data:/var/lib/mysql mysql
