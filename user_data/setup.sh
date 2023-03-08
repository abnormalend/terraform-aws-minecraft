#!/bin/bash

# Create user
groupadd minecraft
useradd --system --shell /bin/nologin --home /opt/minecraft -g minecraft minecraft

# Install packages
yum update
yum -y upgrade

# Install java
sudo rpm --import https://yum.corretto.aws/corretto.key 
sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
sudo yum install -y java-16-amazon-corretto-devel

yum install -y python3 git amazon-cloudwatch-agent      # Python needed for mcstatus
pip3 install requests mcstatus boto3                    # mcstatus let's us check the server stats easily

# Create minecraft directories
mkdir -p /opt/{minecraft/server/plugins,resources,s3_resources}


# get the S3 files
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export MINECRAFT_HOME="/opt/minecraft"
export_statement=$(aws ec2 describe-tags --region "$REGION" \
                        --filters "Name=resource-id,Values=$INSTANCE_ID" \
                        --query 'Tags[?!contains(Key, `:`)].[Key,Value]' \
                        --output text | \
                        sed -E 's/^([^\t]+)[\t]+([^\n]+)$/export \1="\2"/g')

eval $export_statement

# unzip /tmp/resources.zip -d /opt/resources
echo "running aws s3 sync $SetupUrl /opt/resources"
aws s3 sync $SetupUrl /opt/resources
echo "running aws s3 sync $FilesUrl /opt/s3_resources"
aws s3 sync $FilesUrl /opt/s3_resources
# source /opt/resources/export_instance_tags.sh
echo "contents of /opt/resources"
ls /opt/resources
echo "contents of /opt/s3_resources"
ls /opt/s3_resources
# echo $MINECRAFT_HOME


# Get the minecraft tools from github
git clone https://github.com/abnormalend/minecraft_aws_tools.git /opt/minecraft_aws_tools
export MINECRAFT_TOOLS_HOME="/opt/minecraft_aws_tools"
source /opt/minecraft_aws_tools/install.sh

# Start putting things where they belong
#TODO cp -r /opt/s3_resources/plugins/* /opt/minecraft/server/plugins
cp /opt/resources/export_instance_tags.sh /etc/profile.d

#Set EULA
echo "eula=true" > /opt/minecraft/server/eula.txt

cp /opt/resources/server.properties /opt/minecraft/server
cp /opt/resources/whitelist.json /opt/minecraft/server
cp /opt/resources/ops.json /opt/minecraft/server
cp /opt/resources/server.conf /opt/minecraft/server

# Update DNS
python3 /opt/minecraft_aws_tools/dns_updater/dns_updater.py

# Use paper updater to get the server jar
python3 /opt/minecraft_aws_tools/paper_updater/paper_updater.py

# Try to restore a backup for this hostname
source /opt/minecraft_aws_tools/s3_backup/s3_restore.sh

# Set ownership
chown minecraft:minecraft -R /opt/minecraft

# Run dynamic memory script
source /opt/minecraft_aws_tools/dynamic_memory/dynamic_memory.sh

#Start up cloudwatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/resources/cloudwatch.json
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a start


#Copy Service
cp /opt/resources/minecraft@.service /etc/systemd/system/minecraft@.service
chmod 755 /etc/systemd/system/minecraft@.service

#Enable Service
systemctl enable minecraft@server

#Start Service
service minecraft@server start