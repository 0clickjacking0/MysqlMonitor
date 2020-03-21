#!/bin/sh
#*************************************************************
#Author: xianyu123
#Date:  2020-03-21
#FileName:      MysqlMonitor.sh
#*************************************************************

MYSQL="mysql"
config_path='config.ini'
ip=`sed -n '2,2p' $config_path | sed 's/h.*=\([0-9].*\).*/\1/g'`
port=`sed -n '3,3p' $config_path | sed 's/p.*=\([0-9]*\).*/\1/g'`
user=`sed -n '4,4p' $config_path | sed 's/u.*=\(.*\).*/\1/g'`
pass=`sed -n '5,5p' $config_path | sed 's/p.*=\(.*\).*/\1/g'`
db=`sed -n '6,6p' $config_path | sed 's/d.*=\(.*\).*/\1/g'`
charset=`sed -n '7,7p' $config_path | sed 's/c.*=\(.*\).*/\1/g'`

# 数据库连接函数
function con_mysql(){
    echo $(mysql -u$user -p$pass -h$ip -P$port --default-character-set=$charset -D $db -se "$1" 2>/dev/null)
}

# 当tail -f终止时调用这里
trap 'onCtrlC' INT
function onCtrlC () {
    con_mysql "SET GLOBAL general_log = 'OFF';"
    echo `date "+\033[36m[%H:%M:%S] \033[0m"` " SET GLOBAL general_log = 'OFF';"
}

# 设置数据库时间为系统的时区
con_mysql "set global log_timestamps='SYSTEM';"

# 查看数据库临时日志是否开启
value=`con_mysql "SHOW VARIABLES LIKE \"general_log%\";"`

my_array=() # 存储临时日志开启状态和保存日志的地址
n=0
for val in $value
do
   my_array[$n]=$val
   ((n++))
done

# 如果临时日志状态为关闭,那么就开启
if [ "${my_array[1]}" == "OFF" ] 
then
    con_mysql "SET GLOBAL general_log = 'ON';"
    echo `date "+\033[36m[%H:%M:%S] \033[0m"` ' SET GLOBAL general_log = "ON";'
fi
path=${my_array[3]} # 日志的地址

# 监听日志
sudo tail -f $path | awk '/Execute|Query/{str=gsub(/.*T|\..+/,"",$1);$1="[""\033[36m"$1"\033[0m""]";$2="";$3="";print $0}'