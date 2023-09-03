#!/bin/bash
# if you want the variables to be avaialble in the terminal make sure to source the script
#two options
#source vpc_mysql.sh
#. ./vpc_mysql.sh

#create_vpc
vpc_id=`aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text`

#create subnets
public_subnet_1=`aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.0.0/24 --availability-zone us-west-2a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public subnet 1}]' --query Subnet.SubnetId --output text`

private_subnet_1=`aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.1.0/24 --availability-zone us-west-2a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private subnet 1}]' --query Subnet.SubnetId --output text`

public_subnet_2=`aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.2.0/24 --availability-zone us-west-2b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public subnet 2}]' --query Subnet.SubnetId --output text`

private_subnet_2=`aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.3.0/24 --availability-zone us-west-2b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private subnet 2}]' --query Subnet.SubnetId --output text`

#elastic ip allocation
nat_elastic_ip=`aws ec2 allocate-address --query AllocationId --output text`

#create nat gateway
nat_gateway=`aws ec2 create-nat-gateway --subnet-id $public_subnet_1 --allocation-id $nat_elastic_ip --query NatGateway.NatGatewayId --output text`

#create internet gateway
internet_gateway=`aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text`

#attach internet gateway to vpc
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $internet_gateway

#create public route table
public_route_table=`aws ec2 create-route-table --vpc-id $vpc_id --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=public route table}]' --query RouteTable.RouteTableId --output text`

#create private route table
private_route_table=`aws ec2 create-route-table --vpc-id $vpc_id --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=private route table}]' --query RouteTable.RouteTableId --output text`


#add route to internet gateway for public route table
aws ec2 create-route --route-table-id $public_route_table --destination-cidr-block 0.0.0.0/0 --gateway-id $internet_gateway

#add route to nat gateway for private route table
aws ec2 create-route --route-table-id $private_route_table --destination-cidr-block 0.0.0.0/0 --gateway-id $nat_gateway

#associate public subnets to route table
aws ec2 associate-route-table --subnet-id $public_subnet_1 --route-table-id $public_route_table
aws ec2 associate-route-table --subnet-id $public_subnet_2 --route-table-id $public_route_table

#associate private subnets to route table 
aws ec2 associate-route-table --subnet-id $private_subnet_1 --route-table-id $private_route_table
aws ec2 associate-route-table --subnet-id $private_subnet_2 --route-table-id $private_route_table

#create public security group 
public_security_group=`aws ec2 create-security-group --group-name "public security group" --description "Security group for SSH access" --vpc-id $vpc_id --query GroupId --output text`

#create private security group
private_security_group=`aws ec2 create-security-group --group-name "private security group" --description "private group for SSH access" --vpc-id $vpc_id --query GroupId --output text`

#create inbound rules public security group
aws ec2 authorize-security-group-ingress --group-id $public_security_group --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $public_security_group --protocol tcp --port 3306 --cidr 0.0.0.0/0

#create inbound rules private security group
aws ec2 authorize-security-group-ingress --group-id $private_security_group --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $private_security_group --protocol tcp --port 3306 --cidr 0.0.0.0/0

#create key pair
aws ec2 create-key-pair --key-name mysqlkey --query 'KeyMaterial' --output text > ./mysqlkey.pem
chmod 400 mysqlkey.pem


#create ec2 mysql client
mysql_client_instance=`aws ec2 run-instances \
--image-id ami-002c2b8d1f5b1eb47 --count 1 \
--instance-type t2.micro \
--key-name mysqlkey \
--security-group-ids $public_security_group \
--subnet-id $public_subnet_2 \
--associate-public-ip-address  \
--user-data file://./sql_client_setup.sh \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=sql client}]' \
--query Instances[].InstanceId --output text` 

#create ec2 mysql server
mysql_server_instance=`aws ec2 run-instances \
--image-id ami-002c2b8d1f5b1eb47 --count 1 \
--instance-type t2.micro \
--key-name mysqlkey \
--security-group-ids $private_security_group \
--subnet-id $private_subnet_2 \
--associate-public-ip-address  \
--user-data file://./sql_server_setup.sh \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=sql server}]' \
--query Instances[].InstanceId --output text` 



