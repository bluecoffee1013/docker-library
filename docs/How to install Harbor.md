## 1. 前言
之前使用Docker官方的Registry镜像搭建了私有仓库，但是没有可一个可视化的界面去维护，非常不方便。所幸Vmware推出一个基于官方Registry V2镜像打造的私有仓库项目，今天就来尝试搭建一下。

## 2. 简介
Harbor是VMware公司最近开源的企业级Docker Registry项目, 其目标是帮助用户迅速搭建一个企业级的Docker registry服务。它以Docker公司开源的registry为基础，提供了管理UI, 基于角色的访问控制(Role Based Access Control)，AD/LDAP集成、以及审计日志(Audit logging) 等企业用户需求的功能，同时还原生支持中文。Harbor的每个组件都是以Docker容器的形式构建的，使用Docker Compose来对它进行部署。用于部署Harbor的Docker Compose模板位于docker-compose.yml，由7个容器组成

* harbor-jobservice 是harbor的job管理模块，job在harbor里面主要是为了镜像仓库之前同步使用的

* harbor-adminserver:是harbor系统管理接口，可以修改系统配置以及获取系统信息。

* harbor-db:是harbor的数据库(MySQL)，这里保存了系统的job以及项目、人员权限管理。由于本harbor的认证也是通过数据，在生产环节大多对接到企业的ldap中。

* harbor-log:harbor的日志服务，统一管理harbor的日志。通过inspect可以看出容器统一将日志输出的syslog。

* harbor-ui:是web管理页面，主要是前端的页面和后端CURD的接口

* nginx:负责流量转发和安全验证，对外提供的流量都是从nginx中转，所以开放https的443端口，它将流量分发到后端的ui和正在Docker镜像存储的docker registry。

* registry:由Docker官方的开源registry 镜像构成的容器实例


这几个容器通过Docker link的形式连接在一起，在容器之间通过容器名字互相访问。对终端用户而言，只需要暴露Nginx的服务端口。

## 3. 部署环境
* CentOS 7
* docker  V1.12.6
* docker-compose V1.13
* Harbor V1.1.2 [官网GitHub](https://github.com/vmware/harbor)

## 4. 安装过程
### 4.1 下载Harbor
有离线安装和在线安装包两种，这里下载离线安装包，之后安装会比较快
`wget https://github.com/vmware/harbor/releases/download/v1.1.2/harbor-offline-installer-v1.1.2.tgz`

### 4.2 解压并配置Harbor
#### 4.2.1 解压
`tar xvfz harbor-offline-installer-v1.1.2.tgz`

#### 4.2.2 配置
##### 4.2.2.1 编辑安装模板harbor.cfg
harbor的nginx默认暴露本机的80端口，但是一般80端口都会被占用，我改成8060端口，如下是我的配置文件，有改动的地方我用**标注了，大家也可以根据实际情况进行修改

```
## Configuration file of Harbor

#The IP address or hostname to access admin UI and registry service.
#DO NOT use localhost or 127.0.0.1, because Harbor needs to be accessed by external clients.
#修改成本地IP:暴露端口
** hostname = 192.168.3.42:8060

#The protocol for accessing the UI and token/notification service, by default it is http.
#It can be set to https if ssl is enabled on nginx.
ui_url_protocol = http

#The password for the root user of mysql db, change this before any production use.
db_password = root123

#Maximum number of job workers in job service
max_job_workers = 3

#Determine whether or not to generate certificate for the registry's token.
#If the value is on, the prepare script creates new root cert and private key
#for generating token to access the registry. If the value is off the default key/cert will be used.
#This flag also controls the creation of the notary signer's cert.
customize_crt = on

#The path of cert and key files for nginx, they are applied only the protocol is set to https
#存放认证书的位置
**ssl_cert = ./data/cert/server.crt
**ssl_cert_key = ./data/cert/server.key

#The path of secretkey storage
**secretkey_path = ./data

#Admiral's url, comment this attribute, or set its value to NA when Harbor is standalone
admiral_url = NA

#NOTES: The properties between BEGIN INITIAL PROPERTIES and END INITIAL PROPERTIES
#only take effect in the first boot, the subsequent changes of these properties
#should be performed on web ui

#************************BEGIN INITIAL PROPERTIES************************

#Email account settings for sending out password resetting emails.

#Email server uses the given username and password to authenticate on TLS connections to host and act as identity.
#Identity left blank to act as username.
email_identity =

email_server = smtp.mydomain.com
email_server_port = 25
email_username = sample_admin@mydomain.com
email_password = abc
email_from = admin <sample_admin@mydomain.com>
email_ssl = false

##The initial password of Harbor admin, only works for the first time when Harbor starts.
#It has no effect after the first launch of Harbor.
#Change the admin password from UI after launching Harbor.
# 默认的管理员登录密码
harbor_admin_password = Harbor12345

##By default the auth mode is db_auth, i.e. the credentials are stored in a local database.
#Set it to ldap_auth if you want to verify a user's credentials against an LDAP server.
auth_mode = db_auth

#The url for an ldap endpoint.
ldap_url = ldaps://ldap.mydomain.com

#A user's DN who has the permission to search the LDAP/AD server.
#If your LDAP/AD server does not support anonymous search, you should configure this DN and ldap_search_pwd.
#ldap_searchdn = uid=searchuser,ou=people,dc=mydomain,dc=com

#the password of the ldap_searchdn
#ldap_search_pwd = password

#The base DN from which to look up a user in LDAP/AD
ldap_basedn = ou=people,dc=mydomain,dc=com

#Search filter for LDAP/AD, make sure the syntax of the filter is correct.
#ldap_filter = (objectClass=person)

# The attribute used in a search to match a user, it could be uid, cn, email, sAMAccountName or other attributes depending on your LDAP/AD
ldap_uid = uid

#the scope to search for users, 1-LDAP_SCOPE_BASE, 2-LDAP_SCOPE_ONELEVEL, 3-LDAP_SCOPE_SUBTREE
ldap_scope = 3

#Timeout (in seconds)  when connecting to an LDAP Server. The default value (and most reasonable) is 5 seconds.
ldap_timeout = 5

#Turn on or off the self-registration feature
#是否允许用户注册
self_registration = off

#The expiration time (in minute) of token created by token service, default is 30 minutes
token_expiration = 30

#The flag to control what users have permission to create projects
#The default value "everyone" allows everyone to creates a project.
#Set to "adminonly" so that only admin user can create project.
#只有管理员可以有权限创建项目
**project_creation_restriction = adminonly

#Determine whether the job service should verify the ssl cert when it connects to a remote registry.
#Set this flag to off when the remote registry uses a self-signed or untrusted certificate.
verify_remote_cert = on
#************************END INITIAL PROPERTIES************************
#############
```

##### 4.2.2.2 修改docker-compose.yml
找到proxy那一段代码，将80改成8060

```
 proxy:
    image: vmware/nginx:1.11.5-patched
    container_name: nginx
    restart: always
    volumes:
      - ./common/config/nginx:/etc/nginx:z
    networks:
      - harbor
    ports:
      - 8060:80 //此处原来是80:80
      - 443:443
      - 4443:4443
    depends_on:
      - mysql
      - registry
      - ui
      - log
    logging:
      driver: "syslog"
      options:
        syslog-address: "tcp://127.0.0.1:1514"
        tag: "proxy"
```

#### 4.2.2.3 配置docker
因为docker默认使用的是https连接，而harbor默认使用http连接，所以需要修改docker配置标志insecure registry不安全仓库的主机，当然也可以使用https连接，方法以后我再补充吧。

centos7下是编辑/etc/sysconfig/docker，分别修改**OPTIONS**、**ADD_REGISTRY**、**INSECURE_REGISTRY**这三个参数。

```
# /etc/sysconfig/docker

# Modify these options if you want to change the way the docker daemon runs
OPTIONS='--selinux-enabled=false --log-driver=journald --insecure-registry=192.168.3.42:8060'
if [ -z "${DOCKER_CERT_PATH}" ]; then
    DOCKER_CERT_PATH=/etc/docker
fi

# If you want to add your own registry to be used for docker search and docker
# pull use the ADD_REGISTRY option to list a set of registries, each prepended
# with --add-registry flag. The first registry added will be the first registry
# searched.
#ADD_REGISTRY='--add-registry registry.access.redhat.com'
ADD_REGISTRY='--add-registry 192.168.3.42:8060'

# If you want to block registries from being used, uncomment the BLOCK_REGISTRY
# option and give it a set of registries, each prepended with --block-registry
# flag. For example adding docker.io will stop users from downloading images
# from docker.io
# BLOCK_REGISTRY='--block-registry'

# If you have a registry secured with https but do not have proper certs
# distributed, you can tell docker to not look for full authorization by
# adding the registry to the INSECURE_REGISTRY line and uncommenting it.
# INSECURE_REGISTRY='--insecure-registry'
INSECURE_REGISTRY='--insecure-registry=192.168.3.42:8060'

# On an SELinux system, if you remove the --selinux-enabled option, you
# also need to turn on the docker_transition_unconfined boolean.
# setsebool -P docker_transition_unconfined 1

# Location used for temporary files, such as those created by
# docker load and build operations. Default is /var/lib/docker/tmp
# Can be overriden by setting the following environment variable.
# DOCKER_TMPDIR=/var/tmp

# Controls the /etc/cron.daily/docker-logrotate cron job status.
# To disable, uncomment the line below.
# LOGROTATE=false
#

# docker-latest daemon can be used by starting the docker-latest unitfile.
# To use docker-latest client, uncomment below lines
#DOCKERBINARY=/usr/bin/docker-latest
#DOCKERDBINARY=/usr/bin/dockerd-latest
#DOCKER_CONTAINERD_BINARY=/usr/bin/docker-containerd-latest
#DOCKER_CONTAINERD_SHIM_BINARY=/usr/bin/docker-containerd-shim-latest
```

重启docker

```
#systemctl daemon-reload
#systemctl restart docker.service
```

另外需要注意的是，之后所有需要从镜像库拉取镜像的主机都需要重复**4.2.2.3**这一小节的步骤。

##### 4.2.2.4 初始化安装脚本及配置文件
`#./prepare`

##### 4.2.2.5 执行安装
安装的时候我是使用root用户执行的，因为默认的模板中有很多文件目录权限只有root用户才有权限，如果想使用其他用户安装，需要修改相应配置文件中的文件目录路径。

```
#./install.sh
Note: docker version: 1.12.6
Note: docker-compose version: 1.13.0

[Step 0]: checking installation environment ...
....

[Step 1]: loading Harbor images ...
....

[Step 2]: preparing environment ...
....

[Step 3]: checking existing instance of Harbor ...
....

[Step 4]: starting Harbor ...
....

✔ ----Harbor has been installed and started successfully.----

Now you should be able to visit the admin portal at http://192.168.3.42:8060.
For more details, please visit https://github.com/vmware/harbor .
```

安装过程中会从网络上拉取一些镜像，安装完成后，在任意目录下执行docker ps命令或在harbor目录下执行docker-compose ps，会有如下输出，显示有7个容器

```
#docker-compose ps
       Name                     Command               State                                 Ports
--------------------------------------------------------------------------------------------------------------------------------
harbor-adminserver   /harbor/harbor_adminserver       Up
harbor-db            docker-entrypoint.sh mysqld      Up      3306/tcp
harbor-jobservice    /harbor/harbor_jobservice        Up
harbor-log           /bin/sh -c crond && rm -f  ...   Up      127.0.0.1:1514->514/tcp
harbor-ui            /harbor/harbor_ui                Up
nginx                nginx -g daemon off;             Up      0.0.0.0:443->443/tcp, 0.0.0.0:4443->4443/tcp, 0.0.0.0:8060->80/tcp
registry             /entrypoint.sh serve /etc/ ...   Up      5000/tcp
```


## 5. 使用
### 5.1 访问登录页
打开[http://192.168.3.42:8060](192.168.3.42:8060),默认用户及密码是admin/Harbor12345。

![harbor登录页](http://o8t0lnddw.bkt.clouddn.com/harbor%E9%A6%96%E9%A1%B5.png)

之前我在 harbor.cfg 中将 self_registration 属性设置为 off ，那么普通用户将无法自己实现注册，只能由管理员创建用户，否则在页面上可以看到注册按钮。

### 5.2 验证镜像上传
#### 5.2.1 创建用户
![创建用户](http://o8t0lnddw.bkt.clouddn.com/%E5%88%9B%E5%BB%BA%E7%94%A8%E6%88%B7.png)

#### 5.2.2 创建项目
![创建项目](http://o8t0lnddw.bkt.clouddn.com/%E6%96%B0%E5%BB%BA%E9%A1%B9%E7%9B%AE.png)

![创建项目完成](http://o8t0lnddw.bkt.clouddn.com/%E6%96%B0%E5%BB%BA%E9%A1%B9%E7%9B%AE-%E5%AE%8C%E6%88%90.png)

#### 5.2.3 为新项目添加成员
只有项目管理员及开发人员的角色才可以push镜像，其他角色的人员只有pull镜像的权限。
![添加项目成员](http://o8t0lnddw.bkt.clouddn.com/%E9%A1%B9%E7%9B%AE%E6%B7%BB%E5%8A%A0%E6%88%90%E5%91%98.png)

#### 5.2.4 push镜像到镜像仓库
登录到某台主机上，主机上有一个busybox镜像

```
# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
docker.io/busybox   latest              c75bebcdd211        6 weeks ago         1.106 MB
```

为这个镜像打上标签，名称一定要标准(registryAddress[:端口]/项目/imageName[:tag] )

`docker tag busybox 192.168.3.42:8060/core/busybox`

再看一下目前的镜像

```
# docker images
REPOSITORY                      TAG                 IMAGE ID            CREATED             SIZE
docker.io/busybox               latest              c75bebcdd211        6 weeks ago         1.106 MB
192.168.3.42:8060/core/busybox   latest              c75bebcdd211        6 weeks ago         1.106 MB
```

登录仓库

```
# docker login -u docker -p Docker12345 192.168.3.42:8060
Login Succeeded
```

push镜像

```
# docker push 192.168.3.42:8060/core/busybox
The push refers to a repository [192.168.3.42:8060/core/busybox]
4ac76077f2c7: Pushed
latest: digest: sha256:c79345819a6882c31b41bc771d9a94fc52872fa651b36771fbe0c8461d7ee558 size: 527
```

在另外的主机上验证是否可以下载刚才上传到仓库中的镜像

```
# docker login -u docker -p Docker12345 192.168.3.42:8060
Login Succeeded
# docker pull 192.168.3.42:8060/core/busybox
```

在Harbor的WEB界面验证
![查看镜像](http://o8t0lnddw.bkt.clouddn.com/%E9%95%9C%E5%83%8F%E6%9F%A5%E7%9C%8B.png)