#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
#Logs Folder & File
LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log" #/var/log/shell-script/redis.log
START_TIME=$(date +%s)
mkdir -p $LOG_FOLDER
echo -e "$Y script started at :$(date) $N" | tee -a $LOG_FILE
#ROOT CHECK
USERID=$(id -u)
if [ USERID -ne 0 ]; then
    echo "$R ERROR:: please run these script at root $N" | tee -a $LOG_FILE
    exit 1
fi
VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$R ERROR:: $2 failed $N " | tee -a $LOG_FILE
        exit1
    else
        echo -e "$G success :: $2 completed $N" | tee -a $LOG_FILE
fi 
}    
dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disabling default redis"
dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enabling default redis"
dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c /protected-mode/ NO' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connections to redis"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "enabling redis"
systemctl start redis &>>$LOG_FILE
VALIDATE $? "restarting redis"
END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "script executed in : $Y $TOTAL_TIME seconds$N "
           