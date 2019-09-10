#!/bin/bash

#define variables
#AWS_REGION=us-east-1
#AVALAB_ZONE=us-east-1a

# all commands execute under usual bash user

#: '
echo "#1 Создать свою собственную Amazon VPC."

aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region us-east-1 --output json
#VPCID=$(aws ec2 describe-vpcs --query Vpcs[0].VpcId | sed -e 's/\"//g')
# If "jq"  installed in OS you may use same code's kind - aws ec2 describe-vpcs | jq '.Vpcs[0].VpcId' | tr -d '""'

#echo "VPCID was created = $VPCID"


echo "#2 Добавить “ test ”  -тэг для созданной VPC."

aws ec2 create-tags --resources $(aws ec2 describe-vpcs --query Vpcs[0].VpcId | sed -e 's/\"//g') --tags Key=Name,Value=test

echo "#3 Разрешить использование DNS hostnames для созданной VPC."

aws ec2  modify-vpc-attribute --enable-dns-hostnames --vpc-id $(aws ec2 describe-vpcs --query Vpcs[0].VpcId | sed -e 's/\"//g')

#'

echo "#4 Создать 2 subnets для созданной VPC. Один subnet должен быть публичным(доступен из интернета), второй - оставаться приватным."

aws ec2 create-subnet --vpc-id $VPCID --cidr-block 10.0.1.0/28 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id $VPCID --cidr-block 10.0.2.0/28 --availability-zone us-east-1a

#aws ec2 describe-subnets --query Subnets[].SubnetId
aws ec2 create-tags --resources \
 $(aws ec2 describe-subnets --output json --query Subnets[0].SubnetId | sed -e 's/\"//g') --tags Key=Name,Value=public

aws ec2 create-tags --resources  \
$(aws ec2 describe-subnets --output json --query Subnets[1].SubnetId | sed -e 's/\"//g') --tags Key=Name,Value=private


#############################
### for public subnet
# creating internet gateway
aws ec2 create-internet-gateway

# attach internet gateway to VPC
aws ec2 attach-internet-gateway \
--internet-gateway-id $(aws ec2 describe-internet-gateways --query InternetGateways[0].InternetGatewayId | sed -e 's/\"//g') \
--vpc-id $(aws ec2 describe-vpcs --query Vpcs[0].VpcId | sed -e 's/\"//g')

# create route table
aws ec2 create-route-table --vpc-id $(aws ec2 describe-vpcs --query Vpcs[0].VpcId | sed -e 's/\"//g')
aws ec2 create-tags --resources  \
$(aws ec2 describe-route-tables --query RouteTables[0].RouteTableId | sed -e 's/\"//g') --tags Key=Name,Value=public

# add internet gateway rule
aws ec2 create-route \
--route-table-id $(aws ec2 describe-route-tables --query RouteTables[0].RouteTableId | sed -e 's/\"//g') \
--destination-cidr-block 0.0.0.0/0 \
--gateway-id $(aws ec2 describe-internet-gateways --query InternetGateways[0].InternetGatewayId | sed -e 's/\"//g')

# associate route table to public subnet
aws ec2 associate-route-table \
--route-table-id $(aws ec2 describe-route-tables --query RouteTables[0].RouteTableId | sed -e 's/\"//g') \
--subnet-id $(aws ec2 describe-subnets --output json --query Subnets[0].SubnetId | sed -e 's/\"//g')

####################################


#5 Создать “ test-BRdD5U0g3G97 ” Amazon S3 bucket.
 aws s3api create-bucket --bucket test-BRdD5U0g3G97 --region us-east-1

#test-brdd5u0g3g97
#6 Настроить CORS для созданной Amazon S3 bucket, чтобы разрешить "PUT", POST","DELETE"-запросы только c домена “test-BRdD5U0g3G97.com”, а "HEAD", "GET"-запросы с любого источника.


#7 Создать нового пользователя в Amazon IAM c возможностью программного доступа только к “� test-BRdD5U0g3G97” Amazon S3 buсket и посредством только PUT-запросов.


#8 Создать экземпляр Amazon RDS(PostgreSQL) cо значением “� test-db� ” для db-instance-identifier.
### for sequring purposes you should use a variable instead of the real pass or use different secure  way 

aws rds create-db-instance \
--allocated-storage 1 \
--db-instance-class db.t2.micro \
--db-instance-identifier test-db \
--engine postgres \
--master-username master  \
--master-user-password secret99

##    --availability-zone us-east-1a \

##  --engine-version 10.6 \


#9 Сделать snapshot для созданного Amazon RDS.
aws rds create-db-snapshot \
    --db-instance-identifier test-db \
    --db-snapshot-identifier test-dbsnapshot

echo "# 10Создать второй экземпляр Amazon RDS cо значением “� test-db-restore� ” для db-instance-identifier и который будет восстановлен из snapshot(пункт 9)."

aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier test-db-restore \
    --db-snapshot-identifier test-dbsnapshot


echo "#11 Удалить созданные Amazon RDS-инстансы."
aws rds delete-db-instance --db-instance-identifier test-db-restore --skip-final-snapshot
aws rds delete-db-instance --db-instance-identifier test-db --skip-final-snapshot

aws rds delete-db-snapshot  --db-snapshot-identifier test-dbsnapshot
### !!! you have to  delete automated snapshots which was created by RDS


#12 Создать Amazon Security Group, разрешить доступ к 80 порту для всех, а к 22 порту только для вашего IP-адреса.

aws ec2 create-security-group --group-name test --description "testgroup" \
--vpc-id $(aws ec2 describe-vpcs --query Vpcs[0].VpcId | sed -e 's/\"//g')

aws ec2 authorize-security-group-ingress --group-id \
$(aws ec2 describe-security-groups  --query SecurityGroups[0].GroupId | sed -e 's/\"//g') \
--protocol tcp --port 80 --cidr 0.0.0.0/0  \
--protocol tcp --port 22 --cidr $(dig +short myip.opendns.com @resolver1.opendns.com)/32

###    --ip-permissions IpProtocol=icmp,FromPort=3,ToPort=4,IpRanges='[{CidrIp=0.0.0.0/0}]'

#13 Создать экземпляр Amazon EC2 в публичной subnet и с созданной в пункте 11 Security Group.

: '
aws opsworks --region us-east-1 create-instance --ami-id  ami-0c46f9f09e3a8c2b5 \
 --stack-id  --layer-ids  --instance-type t2.micro \
--hostname  testweb
'

: '
PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets \
| jq '.Subnets[] | select(contains({Tags: [{Key: "Name"},{Value: "public"}]}) )' | \
grep SubnetId | awk '{print $2}' | sed -e 's/\"//g' | sed -e 's/\,//g')

aws ec2 run-instances --image-id ami-0c46f9f09e3a8c2b5  --count 1 --instance-type t2.micro \
--security-group-ids $(aws ec2 describe-security-groups  --query SecurityGroups[0].GroupId | sed -e 's/\"//g') \
--subnet-id $PUBLIC_SUBNET_ID
'

aws ec2 run-instances --image-id ami-0c46f9f09e3a8c2b5  --count 1 --instance-type t2.micro \
--security-group-ids $(aws ec2 describe-security-groups  --query SecurityGroups[0].GroupId | sed -e 's/\"//g') \
--subnet-id $(aws ec2 describe-subnets \
| jq '.Subnets[] | select(contains({Tags: [{Key: "Name"},{Value: "public"}]}) )' \
| grep SubnetId | awk '{print $2}' | sed -e 's/\"//g' | sed -e 's/\,//g')

## --ssh-key-name  APKAJI6RMM6HGM36HRHQ \
## you should use your ssh key pair

#14 Подключиться по ssh к созданному EC2, установить и запустить Nginx.
#15 Проверить, что по 80 порту для EC2 возвращается дефолтная страница Nginx.
#16 Удалить созданный EC2-инстанс."

: '
!!!� � После выполнения тестового задания не забудьте удалить все созданные
ресурсы с вашего Amazon AWS-аккаунта, чтобы исключить дальнейшую
тарификацию и списания денег с вашей карточки после истечения(или выхода из)
Amazon Free Tier.
'

exit 0