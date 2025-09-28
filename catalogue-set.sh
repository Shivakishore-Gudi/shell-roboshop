#!/bin/bash
set -euo pipefail
trap 'echo "There is an error in $LINENO, Command is: $BASH_COMMAND"' ERR

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=mongodb.gskdaws.fun
SCRIPT_DIR=$(cd $(dirname $0); pwd)

mkdir -p $LOGS_FOLDER
echo "script started executed at: $(date)"

USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo "ERROR:: please run these script with root privilage"
    exit 1
fi    

###NodeJS###
dnf module disable nodejs -y &>>$LOG_FILE
dnf module enable nodejs:20 -y &>>$LOG_FILE
dnf install nodejs -y &>>$LOG_FILE

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
else
    echo -e "user already exists ... $Y Skipping $N"
fi 

mkdir -p /app 
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
cd /app

rm -rf /app/*
unzip /tmp/catalogue.zip &>>$LOG_FILE
npm install &>>$LOG_FILE

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>>$LOG_FILE

INDEX=$(mongosh --host mongodb.daws86s.fun --quiet --eval "db.adminCommand('listDatabases').databases.map(db => db.name).indexOf('catalogue')")
if [ $INDEX -le 0 ];then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
else
    echo -e "catalogue products already loaded ... $Y Skipping $N "
fi    
systemctl restart catalogue
echo "Restart catalogu ... $G Success $N 