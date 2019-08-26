#!/usr/bin/env bash

Folder="/usr/local/glider"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	fi
	bit=`uname -m`
}

check_pid(){
	PID=`ps -ef | grep "glider" | grep -v "grep" | grep -v "glider.sh"| grep -v "init.d" | grep -v "service" | awk '{print $2}'`
}

get_ip(){
	ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ip}" ]]; then
		ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ip}" ]]; then
			ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ip}" ]]; then
				ip="VPS_IP"
			fi
		fi
	fi
}

check_new_ver(){
	echo -e "${Info} 请输入 glider 版本号，格式如：[ 1.34.0 ]，获取地址：[ https://github.com/nadoo/glider/releases ]"
	read -e -p "默认回车自动获取最新版本号:" glider_new_ver
	if [[ -z ${glider_new_ver} ]]; then
		glider_new_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/nadoo/glider/releases | grep -o '"tag_name": ".*"' |head -n 1| sed 's/"//g;s/v//g' | sed 's/tag_name: //g')
		if [[ -z ${glider_new_ver} ]]; then
			echo -e "${Error} glider 最新版本获取失败，请手动获取最新版本号[ https://github.com/nadoo/glider/releases ]"
			read -e -p "请输入版本号 [ 格式如 1.34.0 ] :" glider_new_ver
			[[ -z "${glider_new_ver}" ]] && echo "取消..." && exit 1
		else
			echo -e "${Info} 检测到 glider 最新版本为 [ ${glider_new_ver} ]"
		fi
	else
		echo -e "${Info} 即将准备下载 glider 版本为 [ ${glider_new_ver} ]"
	fi
}

check_install_status(){
	[[ ! -e "/usr/bin/glider" ]] && echo -e "${Error} glider 没有安装，请检查 !" && exit 1
	[[ ! -e "/root/.glider/glider.conf" ]] && echo -e "${Error} glider 配置文件不存在，请检查 !" && [[ $1 != "un" ]] && exit 1
}

download_glider(){
	cd "/usr/local"
	if [[ ${bit} == "x86_64" ]]; then
		bit="amd64"
	elif [[ ${bit} == "i386" || ${bit} == "i686" ]]; then
		bit="386"
	else
		bit="arm64"
	fi
	wget -N --no-check-certificate "https://github.com/nadoo/glider/releases/download/v${glider_new_ver}/glider-v${glider_new_ver}-linux-${bit}.tar.gz"
	glider_name="glider-v${glider_new_ver}-linux-${bit}"
	
	[[ ! -s "${glider_name}.tar.gz" ]] && echo -e "${Error} glider 压缩包下载失败 !" && exit 1
	tar zxvf "${glider_name}.tar.gz"
	[[ ! -e "/usr/local/${glider_name}" ]] && echo -e "${Error} glider 解压失败 !" && rm -rf "${glider_name}.tar.gz" && exit 1
	rm -rf "${glider_name}.tar.gz"
	mv "/usr/local/${glider_name}" "${Folder}"
	[[ ! -e "${Folder}" ]] && echo -e "${Error} glider 文件夹重命名失败 !" && rm -rf "${glider_name}.tar.gz" && rm -rf "/usr/local/${glider_name}" && exit 1
	rm -rf "${glider_name}.tar.gz"
	cd "${Folder}"
	chmod +x glider
	cp glider /usr/bin/glider
	mkdir /root/.glider
	wget --no-check-certificate https://raw.githubusercontent.com/ooxoop/glider-install/master/glider.conf.example -O /root/.glider/glider.conf
	echo -e "${Info} glider 主程序安装完毕！开始配置服务文件..."
}

service_glider(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ooxoop/glider-install/master/glider_centos.service -O /etc/init.d/glider; then
			echo -e "${Error} glider服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/glider
		chkconfig --add glider
		chkconfig glider on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ooxoop/glider-install/master/glider_debian.service -O /etc/init.d/glider; then
			echo -e "${Error} glider服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/glider
		update-rc.d -f glider defaults
	fi
	echo -e "${Info} glider服务 管理脚本安装完毕 !"
}

config_ss(){
	Set_config_port
	Set_config_password
	Set_config_method
	ss_link="ss://${ss_method}:${ss_password}@:${port}"
	if [[ -e "/root/.glider/glider.conf" ]]; then
		rm -rf /root/.glider/glider.conf
	fi
	echo -e "verbose=True\nlisten=${ss_link}" >> /root/.glider/glider.conf
}

Set_config_port(){
	while true
	do
	echo -e "请输入要设置的 端口"
	read -e -p "(默认: 9999):" port
	[[ -z "$port" ]] && port="9999"
	echo $((${port}+0)) &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${port} -ge 1 ]] && [[ ${port} -le 65535 ]]; then
			echo && echo ${Separator_1} && echo -e "	端口 : ${Green_font_prefix}${port}${Font_color_suffix}" && echo ${Separator_1} && echo
			break
		else
			echo -e "${Error} 请输入正确的数字(1-65535)"
		fi
	else
		echo -e "${Error} 请输入正确的数字(1-65535)"
	fi
	done
}

Set_config_password(){
	echo "请输入要设置的Shadowsocks账号 密码"
	read -e -p "(默认: somebody):" ss_password
	[[ -z "${ss_password}" ]] && ss_password="somebody"
	echo && echo ${Separator_1} && echo -e "	密码 : ${Green_font_prefix}${ss_password}${Font_color_suffix}" && echo ${Separator_1} && echo
}

Set_config_method(){
	echo -e "请选择要设置的Shadowsocks账号 加密方式
	
${Green_font_prefix}1.${Font_color_suffix} RC4-MD5

${Green_font_prefix}2.${Font_color_suffix} AES-128-GCM
${Green_font_prefix}3.${Font_color_suffix} AES-192-GCM
${Green_font_prefix}4.${Font_color_suffix} AES-256-GCM

${Green_font_prefix}5.${Font_color_suffix} CHACHA20
${Green_font_prefix}6.${Font_color_suffix} CHACHA20-IETF
${Green_font_prefix}7.${Font_color_suffix} XCHACHA20

${Green_font_prefix}8.${Font_color_suffix} CHACHA20-IETF-POLY1305
${Green_font_prefix}9.${Font_color_suffix} XCHACHA20-IETF-POLY1305
${Tip} CHACHA20-*系列加密方式，需要额外安装依赖 libsodium ，否则会无法启动glider !" && echo
	read -e -p "(默认: 6. CHACHA20-IETF):" ss_method
	[[ -z "${ss_method}" ]] && ss_method="6"
	if [[ ${ss_method} == "1" ]]; then
		ss_method="RC4-MD5"
	elif [[ ${ss_method} == "2" ]]; then
		ss_method="AEAD_AES_128_GCM"
	elif [[ ${ss_method} == "3" ]]; then
		ss_method="AEAD_AES_192_GCM"
	elif [[ ${ss_method} == "4" ]]; then
		ss_method="AEAD_AES_256_GCM"
	elif [[ ${ss_method} == "5" ]]; then
		ss_method="CHACHA20"
	elif [[ ${ss_method} == "6" ]]; then
		ss_method="CHACHA20-IETF"
	elif [[ ${ss_method} == "7" ]]; then
		ss_method="XCHACHA20"
	elif [[ ${ss_method} == "8" ]]; then
		ss_method="AEAD_CHACHA20_IETF_POLY1305"
	elif [[ ${ss_method} == "9" ]]; then
		ss_method="AEAD_XCHACHA20_IETF_POLY1305"
	else
		ss_method="CHACHA20-IETF"
	fi
	echo && echo ${Separator_1} && echo -e "	加密 : ${Green_font_prefix}${ss_method}${Font_color_suffix}" && echo ${Separator_1} && echo
}

View_config(){
	listen=`cat /root/.glider/glider.conf | grep -v '#' | grep "listen=" | awk -F "=" '{print $NF}'`
	if [[ "${listen}" != "" ]]; then
		echo -e "当前监听端口的协议是： 
${Green_font_prefix}${listen}${Font_color_suffix}"
	else
		echo "读取不到配置信息，请检查配置文件"
	fi
	forward=`cat /root/.glider/glider.conf | grep -v '#' | grep "forward=" | awk -F "=" '{print $NF}'`
	if [[ "${forward}" != "" ]]; then
		echo -e "监听接收的数据将转发到： 
${Green_font_prefix}${forward}${Font_color_suffix}"
	fi
}

Set_config(){
	echo && echo -e "glider 快速配置，请选择你需要的 配置

${Green_font_prefix}1.${Font_color_suffix} 设置一个Shadowsocks代理
--部署一个普通的ss代理
${Green_font_prefix}2.${Font_color_suffix} 设置一个支持网易云音乐解锁的Shadowsocks代理
--该选项将会自动部署安装网易云音乐解锁代理 UnblockNeteaseMusic
${Green_font_prefix}3.${Font_color_suffix} 设置一个Socks5代理，将该代理转发到Shadowsocks代理
--在国内中转部署，可作为telegram内置代理使用，出国协议为ss" && echo
	read -e -p "默认：取消" config_code
	[[ -z "${config_code}" ]] && config_code="0"
	if [[ ${config_code} == "1" ]]; then
		config_ss
		Restart_glider
	elif [[ ${config_code} == "2" ]]; then
		config_ss_music
	elif [[ ${config_code} == "3" ]]; then
		config_ss_telegram
	else
		exit 1
	fi
}

Install_glider(){
	check_sys
	check_new_ver
	download_glider
	service_glider
	echo -e "glider 已安装完成！请重新运行脚本进行配置~"
}

Start_glider(){
	check_install_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} glider 正在运行，请检查 !" && exit 1
	/etc/init.d/glider start
	View_config
}

Stop_glider(){
	check_install_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} glider 没有运行，请检查 !" && exit 1
	/etc/init.d/glider stop
}

Restart_glider(){
	check_install_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/glider stop
	/etc/init.d/glider start
	View_config
}


echo && echo -e " glider 一键安装管理脚本beta ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
 -- ooxoop | lajiblog.com --

${Green_font_prefix} 1.${Font_color_suffix} 安装 glider
————————————
${Green_font_prefix} 2.${Font_color_suffix} 启动 glider
${Green_font_prefix} 3.${Font_color_suffix} 停止 glider
${Green_font_prefix} 4.${Font_color_suffix} 重启 glider
————————————
${Green_font_prefix} 5.${Font_color_suffix} 查看 当前配置
${Green_font_prefix} 6.${Font_color_suffix} 设置 配置文件
${Green_font_prefix} 7.${Font_color_suffix} 打开 配置文件
${Green_font_prefix} 8.${Font_color_suffix} 查看 日志文件
————————————" && echo
if [[ -e "/usr/bin/glider" ]]; then
	check_pid
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
read -e -p " 请输入数字 [0-10]:" num
case "$num" in
	1)
	Install_glider
	;;
	2)
	Start_glider
	;;
	3)
	Stop_glider
	;;
	4)
	Restart_glider
	;;
	5)
	View_config
	;;
	6)
	Set_config
	;;
	7)
	vi /root/.glider/glider.conf
	Restart_glider
	;;
	8)
	cat /root/.glider/glider.log
	;;
	*)
	echo "请输入正确数字 [0-10]"
	;;
esac


