#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)

if [ $USERID -ne 0 ]; then
    echo "ERROR:: please run these script with root privilage"
    exit 1
fi    

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo "Error:: $2 is ... $R failed $N"
        exit 1
    else
        echo "$2 is ... $G success $N" 
    fi 
}

cp mongo.repo vim /etc/yum.repos.d/mongo.repo
VALIDATE $? "adding mongo repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "installing mongodb"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "enable mongodb"

systemctl start mongod
VALIDATE $? "Enable mongodb"

