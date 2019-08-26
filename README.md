# glider-install
glider一键安装脚本 <br>
glider项目地址： https://github.com/nadoo/glider

Centos 7.3 / Ubuntu 16.04 / Debian 8.9 下测试通过
```

 glider 一键安装管理脚本beta [v]
 -- ooxoop | lajiblog.com --

 1. 安装 glider
————————————
 2. 启动 glider
 3. 停止 glider
 4. 重启 glider
————————————
 5. 查看 当前配置
 6. 设置 配置文件
 7. 打开 配置文件
 8. 查看 日志文件
————————————

 当前状态: 已安装 并 已启动

 请输入数字 [0-10]:

 
```


配置文件还是要自己写，有空再更了

### 配置文件简单举例说明 /root/.glider/glider.conf
#### listen 监听
支持的协议
```
mixed ss socks5 http redir redir6 tcptun udptun uottun tls unix kcp
```
创建代理，多个代理使用多个 listen 参数即可
```
#开启调试模式
verbose=True
#创建一个http(s)/socks混合代理，监听端口6666
listen=:6666
#创建一个http代理，监听端口5555
listen=http://:5555
#创建一个ss代理，监听端口4444
listen=ss://RC4-MD5:pass@:4444
```
#### forward 转发
支持的协议
```
reject ss socks5 http ssr vmess tls ws unix kcp simple-bfs
```
创建代理，并将代理的流量转发到下一个代理
```
#开启调试模式
verbose=True
#创建一个http(s)/socks混合代理，监听端口6666
listen=:6666
#创建一个http代理，监听端口5555
listen=http://:5555
#创建一个ss代理，监听端口4444
listen=ss://RC4-MD5:pass@:4444

#将接受到的数据转发到ss代理
forward=ss://method:pass@1.1.1.1:8443
```

### 协议格式简单说明
#### ss/ssr
格式
```
ss://加密方式:密码@host:端口
ssr://加密方式:密码@host:端口?protocol=协议&protocol_param=协议参数&obfs=混淆&obfs_param=混淆参数
```
支持的加密方式
```
# AEAD Ciphers
AEAD_AES_128_GCM AEAD_AES_192_GCM AEAD_AES_256_GCM AEAD_CHACHA20_POLY1305 AEAD_XCHACHA20_POLY1305
# Stream Ciphers:
AES-128-CFB AES-128-CTR AES-192-CFB AES-192-CTR AES-256-CFB AES-256-CTR CHACHA20-IETF XCHACHA20 CHACHA20 RC4-MD5
# Alias:
chacha20-ietf-poly1305 = AEAD_CHACHA20_POLY1305, xchacha20-ietf-poly1305 = AEAD_XCHACHA20_POLY1305
```

#### v2ray
```
vmess://[security:]uuid@host:port?alterID=num
```
支持的security
```
none, aes-128-gcm, chacha20-poly1305
```
