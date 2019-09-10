



#!/bin/bash

#define variables
#AWS_REGION=us-east-1
#AVALAB_ZONE=us-east-1a

# all commands execute under usual bash user

### I will use default aws region us-east-1 below , if necessary to use unique/special region
### you have to use option (--region <region>). it's right for zones also


echo "#1 Создать свою собственную Amazon VPC."
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region us-east-1 \
 --query 'Vpc.{VpcId:VpcId}'   --output text) && echo "VPC_ID was created = $VPC_ID"


echo "#2 Добавить “ test ”  -тэг для созданной VPC."

aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=vpccdx

echo "#3 Разрешить использование DNS hostnames для созданной VPC."

aws ec2  modify-vpc-attribute --enable-dns-hostnames --vpc-id $VPC_ID


echo "#4 Создать 2 subnets для созданной VPC. Один subnet должен быть публичным(доступен из интернета), второй - оставаться приватным."

SUBN_PUB_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/28 --availability-zone us-east-1a --output text --query 'Subnet.{SubnetId:SubnetId}')
SUBN_PRIV_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/28 --availability-zone us-east-1a --output text --query 'Subnet.{SubnetId:SubnetId}')

echo "create tags for subnets"
aws ec2 create-tags --resources  $SUBN_PUB_ID --tags Key=Name,Value=subn_pub

aws ec2 create-tags --resources  $SUBN_PRIV_ID  --tags Key=Name,Value=subn_priv


echo "#############################"
echo "### for public subnet"

echo " #4.1 creating detatached internet gateway"
IGW_ID=$(aws ec2 create-internet-gateway \
--query 'InternetGateway.{InternetGatewayId:InternetGatewayId}'  --output text) && \
aws ec2 create-tags --resources  $IGW_ID --tags Key=Name,Value=igw_cdx

echo "#4.2 attach internet gateway to VPC"
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

echo "#4.3 create a custom  route table for VPC"
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID \
--query 'RouteTable.{RouteTableId:RouteTableId}'   --output text) && \
aws ec2 create-tags --resources  $ROUTE_TABLE_ID --tags Key=Name,Value=route_table_cdx

echo "#4.4 add internet gateway rule"
echo "(Create a route in the route table that points all traffic (0.0.0.0/0) to the Internet gateway)"
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID \
--destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

echo "#4.7  associate route table to public subnet"
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBN_PUB_ID


echo "#4.8 enable auto-assign public IPv4 address"
aws ec2 modify-subnet-attribute --subnet-id $SUBN_PUB_ID  --map-public-ip-on-launch --region us-east-1





exit 0


#useful commands:
aws ec2 describe-subnets  --query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock,Tags:Tags}' --filters "Name=subnet-id,Values=subnet-0a879bf36192727ac"
