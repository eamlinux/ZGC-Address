环境：Archlinux
下载JDK，https://jdk.java.net/
下载Tomcat ，https://tomcat.apache.org/
解压JDK后mv到/usr/local/jdk，解压tomcat后mv到/usr/local/tomcat
设置变量
```
sudo nano /etc/profile
```
末尾添加内容：
```
# jdk
export JAVA_HOME=/usr/local/jdk
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=.:$JAVA_HOME/lib
```
让变量生效
```
source /etc/profile
```
测试是否成功
```
java -version
```
输出类似内容表示成功
```
java version "10.0.1" 2018-04-17
Java(TM) SE Runtime Environment 18.3 (build 10.0.1+10)
Java HotSpot(TM) 64-Bit Server VM 18.3 (build 10.0.1+10, mixed mode)
```
启动tomcat
```
sudo /usr/local/tomcat/bin/startup.sh
```
如果提示JAVA_HOME错误，在Tomcat的bin目录下的catalina.sh中添加
```export JAVA_HOME=/usr/local/jdk```
再启动***startup.sh***，就可以打开***http://IP:8080***，看到Tomcat的主页。
