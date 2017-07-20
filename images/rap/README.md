## 由于MySQL数据库和Redis是安装在别的服务器上，所以Dockerfile只包含了RAP.war
* 执行build.sh构建RAP的镜像
* 执行run.sh启动RAP，启动访问路径在http://host:9001，端口号可在docker-compose.yml中修改
* 执行stop.sh关闭RAP