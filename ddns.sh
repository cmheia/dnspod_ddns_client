#########################################################################
# File Name: ddns.sh
# Author: cmheia
# mail: cmheia@gmail.com
# Created Time: 2015/04/11 00:55
#########################################################################
#!/opt/bin/bash

#source /etc/profile
export PATH='/opt/sbin:/opt/bin:/opt/usr/sbin:/opt/usr/bin:/bin:/usr/bin:/sbin:/usr/sbin'

################################################################################
# domain config
################################################################################

login_email="api@dnspod.com"
login_password="password"

domain_id_array=( 2317346 )
record_id_array=( 16894439 16894440 16894441 )
sub_domain_array=( "@" "*" "www" )
record_type_array=( "A" "A" "A" )

record_line="%E9%BB%98%E8%AE%A4"
format="json"

################################################################################
# environment config
################################################################################

wan_if_name="ppp0"
work_dir="/root"
log_dir=$work_dir"/ddns"

################################################################################
# generic config
################################################################################

max_checker=16

################################################################################
# constants
################################################################################

# get newest by such command
# wget http://curl.haxx.se/ca/cacert.pem -O /opt/etc/cacert.pem
# curl http://curl.haxx.se/ca/cacert.pem -o /opt/etc/cacert.pem
cacert="/opt/etc/cacert.pem"

saved_global_ip=$log_dir"/saved_global_ip.log"
trace_log=$log_dir"/trace.log"
output_tmp=$log_dir"/output_tmp.log"
output_log=$log_dir"/output.log"
check_time=$log_dir"/checks.log"

################################################################################
# dnspod api
################################################################################

apiurl_ddns="https://dnsapi.cn/Record.Ddns"
apiurl_info="https://dnsapi.cn/Record.Info"
apiurl_modify="https://dnsapi.cn/Record.Modify"

################################################################################
# variables
################################################################################

dns_ip=
global_ip=
interface_ip=
current_checks=

################################################################################
# functions
################################################################################

log_msg()
{
#	logger -t DDNS "$@"
	echo "$@"
}

check_files()
{
	if [ x$1 = x1 ]; then
		if [ ! -d "$log_dir" ] ; then
			mkdir "$log_dir"
			echo "0" >> "$check_time"
		fi
	else
		chmod 600 "$log_dir" -R
		cat "$check_time"
	fi
}

update_check_time()
{
	if [ ! -e "$check_time" ] ; then
		echo "0" >> "$check_time"
	fi

	eval checkd=$(cat "$check_time")
	checkd=$(($checkd+1))
	if [ $checkd -gt $max_checker ] ; then
		echo "0" > "$check_time"
	else
		echo $checkd > "$check_time"
	fi
	current_checks=$checkd
}

update_ddns_naked_record()
{
	curl -s --cacert $cacert -X POST $apiurl_ddns -d "login_email=$login_email&login_password=$login_password&format=$format&domain_id=$1&record_id=$2&record_line=$record_line" --trace "$trace_log" > "$output_tmp"
	log_msg "update ddns record domain_id=$1&record_id=$2"
	log_msg $(cat $output_tmp)
	cat "$output_tmp" >> "$output_log"
	echo -e "" >> "$output_log"
#	echo "login_email=$login_email&login_password=$login_password&format=$format&domain_id=$1&record_id=$2&record_line=$record_line"
}

update_ddns_wildcard_record()
{
#	echo "output_tmp" > "$output_tmp"
	curl -s --cacert $cacert -X POST $apiurl_ddns -d "login_email=$login_email&login_password=$login_password&format=$format&domain_id=$1&record_id=$2&record_line=$record_line&sub_domain=*" --trace "$trace_log" > "$output_tmp"
	log_msg "update ddns record domain_id=$1&record_id=$2"
	log_msg $(cat $output_tmp)
	cat "$output_tmp" >> "$output_log"
	echo -e "" >> "$output_log"
#	echo "login_email=$login_email&login_password=$login_password&format=$format&domain_id=$1&record_id=$2&record_line=$record_line"
}

update_ddns_subname_record()
{
#	echo "output_tmp" > "$output_tmp"
	curl -s --cacert $cacert -X POST $apiurl_ddns -d "login_email=$login_email&login_password=$login_password&format=$format&domain_id=$1&record_id=$2&record_line=$record_line&sub_domain=$3" --trace "$trace_log" > "$output_tmp"
	log_msg "update ddns record domain_id=$1&record_id=$2"
	log_msg $(cat $output_tmp)
	cat "$output_tmp" >> "$output_log"
	echo -e "" >> "$output_log"
#	echo "login_email=$login_email&login_password=$login_password&format=$format&domain_id=$1&record_id=$2&record_line=$record_line"
}

modify_dns_record()
{
	curl -s --cacert $cacert -X POST $apiurl_modify -d "login_email=$login_email&login_password=$login_password&format=$format&domain_id=$1&record_id=$2&sub_domain=$3&value=$4&record_type=$5&record_line=$record_line" > "$output_tmp"
	log_msg "modify dns record domain_id=$1&record_id=$2&sub_domain=$3&value=$4&record_type=$5"
	log_msg $(cat $output_tmp)
	cat "$output_tmp" >> "$output_log"
	echo -e "" >> "$output_log"
}

save_global_ip()
{
echo saving_global_ip:"$global_ip"
cat > "$saved_global_ip"<<-EOF
${global_ip}
EOF
}

get_global_ip()
{
	update_check_time
	echo current_checks:$current_checks
	echo "ip_dectoris:"
	case "$current_checks" in
	 "1" )
		echo "ip138.com"
		global_ip=`curl -s http://1111.ip138.com/ic.asp | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`
	 ;;
	 "2" )
		echo "net.cn"
		global_ip=`curl -s http://www.net.cn/static/customercare/yourip.asp | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -n 1`
	 ;;
	 "3" )
		echo "3322.org"
		global_ip=`curl -s http://members.3322.org/dyndns/getip`
	 ;;
	 "4" )
		echo "123cha.com"
		global_ip=`curl -s http://www.123cha.com/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -n 1`
	 ;;
	 "5" )
		echo "ip123.com"
		global_ip=`curl -s http://www.ip123.com/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1`
	 ;;
	 "6" )
		echo "valu.cn"
		global_ip=`curl -s http://ip.valu.cn/ | grep '</td>' | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`
	 ;;
	 "7" )
		echo "ip.cn"
		global_ip=`curl -s http://www.ip.cn/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -n 1`
	 ;;
	 "8" )
		echo "ip38.com"
		global_ip=`curl -s http://ip38.com/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`
	 ;;
	 "9" )
		echo "dheart.net"
		global_ip=`curl -s http://www.dheart.net/ip/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -n 1`
	 ;;
	 "10" )
		echo "aosoo.com"
		global_ip=`curl -s http://ip.aosoo.com/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`
	 ;;
	 "11" )
		echo "ip2location.com"
		global_ip=`curl -s http://www.ip2location.com/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | tail -1`
	 ;;
	 "12" )
		echo "iplocation.net"
		global_ip=`curl -s http://www.iplocation.net/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -n 1`
	 ;;
	 "13" )
		echo "myip.cn"
		global_ip=`curl -s http://www.myip.cn/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1`
	 ;;
	 "14" )
		echo "ipaddress.com"
		global_ip=`curl -s http://ipaddress.com/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -n 1`
	 ;;
	 "15" )
		echo "slogra.com"
		global_ip=`curl -s http://www.slogra.com/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1`
	 ;;
	 "16" )
		echo "b4secure.com"
		global_ip=`curl -s http://www.b4secure.com/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`
	 ;;
	 "17" )
		echo "dyndns.com"
		global_ip=`curl -s http://checkip.dyndns.com/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`
	 ;;
	 "18" )
		echo "infosniper.net"
		global_ip=`curl -s http://www.infosniper.net/ | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -n 1`
	 ;;
	esac
	save_global_ip
}

get_interface_ip()
{
	interface_ip=`ifconfig $wan_if_name | grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*' | head -1`
}

get_dns_record_info()
{
	dns_ip=`curl -s --cacert $cacert -X POST $apiurl_info -d "login_email=$login_email&login_password=$login_password&format=$format&domain_id=$1&record_id=$2" | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`
}

################################################################################
# start here
################################################################################

cd "$work_dir"
check_files "1"

################################################################################
# get interface ip address
################################################################################
get_interface_ip

valid_interface_ip=`echo "$interface_ip" | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | wc -l`
if [ x"1" != x"$valid_interface_ip" ]; then
	log_msg "interface_ip is illegal, abort."
	exit
fi
echo "valid:interface_ip [$interface_ip]"

################################################################################
# get current global ip address
################################################################################
get_global_ip
if [ -z "$current_global_ip" ]; then
	log_msg "current_global_ip is empty, retry."
	get_global_ip
	if [ -z "$current_global_ip" ]; then
		log_msg "current_global_ip still empty, retry."
		get_global_ip
		if [ -z "$current_global_ip" ]; then
			log_msg "current_global_ip still empty after 3 trys, abort."
			exit
		fi
	fi
fi
echo "fetched:current_global_ip [$current_global_ip]."

valid_global_ip=`cat "$saved_global_ip" | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | wc -l`
if [ x"1" = x"$valid_global_ip" ]; then
	eval current_global_ip=$(cat "$saved_global_ip")
else
	log_msg "current_global_ip is illegal, abort."
	exit
fi
echo "valid:current_global_ip."

################################################################################
# get dns record
################################################################################
get_dns_record_info "${domain_id_array[0]}" "${record_id_array[0]}"

valid_dns_ip=`echo "$dns_ip" | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | wc -l`
if [ x"1" != x"$valid_dns_ip" ]; then
	log_msg "dns_ip is illegal, abort."
	exit
fi
echo "valid:dns_ip [$dns_ip]"

#dns_ip="1.1.1.1"

################################################################################
# if global ip arrdess not equals to interface ip address, your're in innernet.
################################################################################
if [ x"$interface_ip" != x"$current_global_ip" ]; then
	log_msg "innernet, re dial."
	service wan restart
	exit
fi
echo "net type:internet"

################################################################################
# if dns record not equals to interface ip address, re dial happened.
################################################################################
if [ x"$dns_ip" = x"$current_global_ip" ]; then
	echo "nothing to do."
else
	echo "submit new ip."
#	echo "modify dns record domain_id=${domain_id_array[0]}&record_id=${record_id_array[2]}&sub_domain=${sub_domain_array[2]}&value=$current_global_ip&record_type=${record_type_array[2]}"
	modify_dns_record "${domain_id_array[0]}" "${record_id_array[2]}" "${sub_domain_array[2]}" "$current_global_ip" "${record_type_array[2]}"
	modify_dns_record "${domain_id_array[0]}" "${record_id_array[0]}" "${sub_domain_array[0]}" "$current_global_ip" "${record_type_array[0]}"
	modify_dns_record "${domain_id_array[0]}" "${record_id_array[1]}" "${sub_domain_array[1]}" "$current_global_ip" "${record_type_array[1]}"
# renew dns record
#	log_msg "update ddns record from " "$dns_ip" " to " "$current_global_ip"
#	update_ddns_naked_record "${domain_id_array[0]}" "${record_id_array[0]}"
#	update_ddns_wildcard_record "${domain_id_array[0]}" "${record_id_array[1]}"
fi
check_files "2"

################################################################################
# EOF
################################################################################
