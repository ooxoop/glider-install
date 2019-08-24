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
	echo -e "${Info} glider服务 管理脚本下载完成 !"
}

Install_glider(){
	check_sys
	check_new_ver
	download_glider
	service_glider
}

Start_glider(){
	check_install_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} glider 正在运行，请检查 !" && exit 1
	/etc/init.d/glider start
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
}


echo && echo -e " glider 一键安装管理脚本beta ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
 -- ooxoop | lajiblog.com --

${Green_font_prefix} 1.${Font_color_suffix} 安装 glider
————————————
${Green_font_prefix} 2.${Font_color_suffix} 启动 glider
${Green_font_prefix} 3.${Font_color_suffix} 停止 glider
${Green_font_prefix} 4.${Font_color_suffix} 重启 glider
————————————
${Green_font_prefix} 5.${Font_color_suffix} 修改 配置文件
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
	vi /root/.glider/glider.conf
	;;
	*)
	echo "请输入正确数字 [0-10]"
	;;
esac


