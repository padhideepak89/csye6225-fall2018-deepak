#!/bin/bash
#***********************************************************************************
#    AWS VPC Deletion Shell Script
#***********************************************************************************
#
# SYNOPSIS
#    Automates the Deletion of a custom IPv4 VPC, having public subnet, Internet
#    gateway attached to VPC and Route tables
#
# DESCRIPTION
#    This shell script leverages the AWS Command Line Interface (AWS CLI) to
#    automatically delete a custom VPC.
#
#=========================================================================================
#Selection of VPC which need to be deleted, Getting Internet Gateway and Route Table
#=========================================================================================
VPC_NAME=$(aws ec2 describe-vpcs   --query 'Vpcs[*].{VpcId:VpcId}' --filters Name=is-default,Values=false --output text \
 --region us-east-2 2>&1)
if [ $? -ne "0" ]
then
	echo "Parameterizing VPC_ID Failed......"
	exit 1
else
	echo "Select a VPC to be deleted from the list "$VPC_NAME" "
	read VPC_ID
fi
echo "selected VPC is $VPC_ID"


GATEWAY_ID=$(aws ec2 describe-internet-gateways \
 --query 'InternetGateways[*].{InternetGatewayId:InternetGatewayId}' --filters "Name=attachment.vpc-id,Values=$VPC_ID"  --output text 2>&1)
if [ $? -ne "0" ]
then
	echo "Parameterizing GATEWAY_ID Failed......"
	exit 1
else
	echo $GATEWAY_ID
fi

ROUTE_ID=$(aws ec2 describe-route-tables \
 --filters Name=vpc-id,Values=$VPC_ID Name=route.gateway-id,Values=$GATEWAY_ID  --query 'RouteTables[*].{RouteTableId:RouteTableId}' \
 --output text   --region us-east-2 2>&1)
if [ $? -ne "0" ]
then
	echo "Parameterizing ROUTE_ID Failed......"
	exit 1
else
	echo $ROUTE_ID
fi

#=========================================================================================
#Dissociation of Subnet with Route Table
#=========================================================================================
echo "Dissociation of Subnet with route-table"
aws ec2 describe-route-tables --query 'RouteTables[*].Associations[].{RouteTableAssociationId:RouteTableAssociationId}' --route-table-id $ROUTE_ID --output text|while read associate; do  aws ec2 disassociate-route-table --association-id $associate; done
if [ $? -ne "0" ]
then
	echo "Disassociation of subnets Failed......"
	exit 1
else
	echo "Disassociation of subnets done successfully......"
fi

#=========================================================================================
#Delection of Subnets
#=========================================================================================
echo "starting Delection of Subnets..."
while 
sub=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID  --query 'Subnets[*].SubnetId' --output text 2>&1)
[[ ! -z $sub ]]
do
        var1=$(echo $sub | cut -f1 -d" ")
        echo $var1 is deleted 
        aws ec2 delete-subnet --subnet-id $var1
done

#=========================================================================================
#Delection of Route 0.0.0.0/0
#=========================================================================================
echo "deleting route 0.0.0.0_____"
Con=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC_ID --query RouteTables[*].Routes[].{DestinationCidrBlock:DestinationCidrBlock} --output text| grep '0.0.0.0/0' 2>&1)
aws ec2 delete-route --route-table-id $ROUTE_ID --destination-cidr-block $Con
echo "0.0.0.0/0 is deleted successfully"

#=========================================================================================
#Detaching Internet gateway with vpc
#=========================================================================================
echo "detaching internet gateway with vpc"
aws ec2 detach-internet-gateway --internet-gateway-id $GATEWAY_ID --vpc-id $VPC_ID
echo "detaching internet gateway with vpc is done successfully"

#=========================================================================================
#Delection of Internet gateway
#=========================================================================================
echo "deleting internet gateway"
aws ec2 delete-internet-gateway --internet-gateway-id $GATEWAY_ID
echo "Internet gateway is deleted successfully"

#=========================================================================================
#Delection of Route table
#=========================================================================================
echo "deleting route table"
aws ec2 delete-route-table --route-table-id $ROUTE_ID
echo "Route table is deleted successfully"

#=========================================================================================
#Delection of VPC
#=========================================================================================
echo "deleting vpc......"
aws ec2 delete-vpc --vpc-id $VPC_ID
echo "VPC is Deleted successfully"
