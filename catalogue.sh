#!/bin/bash
LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=mongodb.gskdaws.fun
SCRIPT_DIR=$pwd

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

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Creating system user"

mkdir /app 
VALIDATE $? "Creating App Directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue application" 
cd /app
VALIDATE $? "Changing to app directory"
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
cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copy mongo repo"
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installing mongodb client"
mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Load Catalogue products"
systemctl restart catalogue
VALIDATE $? "Restarted catalogue"