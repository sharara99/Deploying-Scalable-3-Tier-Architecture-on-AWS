#!/bin/bash
exec > /var/log/backend-user-data.log 2>&1
set -x

sudo apt update -y
sudo apt install -y curl git

curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

git clone https://github.com/sharara99/front-back-End-project.git /home/ubuntu/app

cd /home/ubuntu/app/BackEnd
npm install

nohup node server.js > server.log 2>&1 &
