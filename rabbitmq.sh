#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
#Logs Folder & File
LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" #/var/log/shell-script/redis.log
SCRIPT_DIR=$pwd
START_TIME=$(date +%s)
mkdir -p $LOGS_FOLDER
echo -e "$Y script started at: $(date) $N" | tee -a $LOG_FILE
#ROOT CHECK

if [ $USERID -ne 0 ]; then
    echo "$R ERROR:: please run these script at root $N" | tee -a $LOG_FILE
    exit 1
fi
VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$R ERROR:: $2 failed $N " | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$G success :: $2 completed $N" | tee -a $LOG_FILE
fi 
}    
cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE

dnf install rabbitmq-server -y &>> $LOG_FILE
VALIDATE $? "installing rabbitmq-server"
systemctl enable rabbitmq-server $LOG_FILE
VALIDATE $? "enabling rabbitmq-server"
systemctl start rabbitmq-server $LOG_FILE
VALIDATE $? "starting rabbitmq-server"
rabbitmqctl add_user roboshop roboshop123 $LOG_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" $LOG_FILE
VALIDATE $? "setting up permissions"
END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "script executed in : $Y $TOTAL_TIME seconds$N "
           