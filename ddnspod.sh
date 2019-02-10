#!/bin/bash
###   A simple DDNS script for dnspod
###   https://github.com/liyiwu/ddnspod

##  config
user_id='12345'
login_token='0123456789abcdef'
domain='www.domain.com'
###   end

echo "Start at $(date)"
agent="ddnspod/0.7(eric@jiangda.info)"
postdata="login_token=${user_id},${login_token}&format=json&domain=${domain#*.}&sub_domain=${domain%%.*}"
#echo $postdata
while :
do
    echo "start to get record from dnspod"
    #echo 'curl -s -A ${agent} -X POST https://dnsapi.cn/Record.List -d "${postdata}"'
    returnjson=$(curl -k -s -A ${agent} -X POST https://dnsapi.cn/Record.List -d "${postdata}")
    returncode=${returnjson#*code\":\"}
    if [ ${returncode%%\"*} == '1' ]
    then
        #echo "${returnjson}"
        break
    fi
    echo "Failed to get the record for ${domain}"
    sleep 1m;
done

returnjson=${returnjson#*records\":[}
record_id=${returnjson#*\[\{\"id\":\"}
record_line_id=${returnjson#*line_id\":\"}
value=${returnjson#*value\":\"}
last_ip=${value%%\"*}
postdata="${postdata}&record_line_id=${record_line_id%%\"*}&record_id=${record_id%%\"*}"

echo "start to get WAN IP from myip.ipip.net ."
current_ip=`curl -k -s myip.ipip.net  | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`

echo "WAN IP is ${current_ip}"                                                                                                                      
echo "DNS IP is ${last_ip}"         
# get WAN IP from openwrt
#current_ip=`ip add show pppoe-wan | grep "inet "|grep -v inet6| cut -d " "  -f6`
if [ ${current_ip} != ${last_ip} ]
then
    date
echo "curl -k -s -A ${agent} -X POST https://dnsapi.cn/Record.Ddns -d '${postdata}'"
    returnjson=`curl -k -s -A ${agent} -X POST https://dnsapi.cn/Record.Ddns -d "${postdata}"`
    returncode=${returnjson#*code\":\"}
    echo "update code is ${returncode}"
    if [ ${returncode%%\"*} = '1' ]
    then
        last_ip=${current_ip}
        echo "Update successful"
    fi
    echo " "
else
    echo "no necessary to update"
fi
