#!/bin/bash
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

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo "Error:: $2 is ... $R failed $N" | tee -a $LOG_FILE
        exit 1
    else
        echo "$2 is ... $G success $N" | tee -a $LOG_FILE
    fi 
}

###NodeJS###
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling Nodjs"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs20"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing Nodjs"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "user already exists ... $Y Skipping $N"
fi 

mkdir -p /app 
VALIDATE $? "Creating App Directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue application" 
cd /app
VALIDATE $? "Changing to app directory"
rm -rf /app/*
VALIDATE $? "removing existing code"
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzip Catalogue"
npm install &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copy systemctl service"
systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enable Catalogue"

systemctl start catalogue
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copy mongo repo"
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installing mongodb client"
INDEX=$(mongosh mongodb.gskdaws.fun --quiet --eval "db.getmongo().getDBNames().indexof('catalogue')")
if [ $INDEX -le 0 ];then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load Catalogue products"
else
    echo -e "catalogue products already loaded ... $Y Skipping $N"
systemctl restart catalogue
VALIDATE $? "Restarted catalogue"