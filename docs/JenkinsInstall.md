# Jenkins 安装

Jenkins 通过 docker 安装， 此处记下 docker 安装 Jenkins 的关键指令:

```shell
docker run -d -u root -p 8080:8080  -v /Users/logan/jenkins_home:/var_jenkins_home --name jenkins jenkins/jenkins:latest
```
