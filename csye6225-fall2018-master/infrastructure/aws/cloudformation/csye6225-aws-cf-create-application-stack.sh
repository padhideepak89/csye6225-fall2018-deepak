#!/bin/bash
#====================================================================================================
# Synopsis: This script is used to create CentOS ec2 instances with security group and Route 53
# in CloudFormation Stack
#====================================================================================================
# Creation of Elastic Compute Cloud stacks
#====================================================================================================
echo "Enter Stack Name for the creation of Ec2 Stack"
read sn
echo ""

#====================================================================================================
#Creation of networking stacks
#====================================================================================================
echo "Enter stack name same as networking script"
read sn1
echo ""

#====================================================================================================
# Validating the CloudFormation Template
#====================================================================================================

Valid=$(aws cloudformation  validate-template --template-body file://csye6225-cf-application.json)
if [ $? -ne "0" ]
then
  echo "$Valid"
  echo "$StackName Template file to build infrastructure is NOT VALID....."
  exit 1
else
  echo " Proceed ahead. CloudFormation Template is VALID......"
  echo ""
fi

#====================================================================================================
# Obtaining Public Subnet Id for VPC
#====================================================================================================

subname="-csye6225-Pubsubnet1"

subname=$sn1$subname

echo "Public Subnet name :"
echo $subname

echo ""

SubnetId=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$subname"  --query 'Subnets[*].SubnetId' --output text 2>&1)

echo "Public Subnet id 1:"
echo $SubnetId

#-----------------------------------------------------------------------------------------------------
subnameA="-csye6225-Pubsubnet2"

subnameA=$sn1$subnameA

echo "Public Subnet name 2:"
echo $subnameA

echo ""

SubnetIdA=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$subnameA"  --query 'Subnets[*].SubnetId' --output text 2>&1)

echo "Public Subnet id 2:"
echo $SubnetIdA

#====================================================================================================
# Obtaining Private Subnet Id for RDS Instance
#====================================================================================================
subname1="-csye6225-Pvtsubnet1"
subname1=$sn1$subname1

echo "Private Subnet name :"
echo $subname1
echo ""

SubnetId1=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$subname1"  --query 'Subnets[*].SubnetId' --output text 2>&1)
echo $SubnetId1


subname2="-csye6225-Pvtsubnet2"
subname2=$sn1$subname2

echo "Private Subnet name :"
echo $subname2
echo ""

SubnetId2=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$subname2"  --query 'Subnets[*].SubnetId' --output text 2>&1)
echo $SubnetId2

#====================================================================================================
# Obtaining Security Group
#====================================================================================================

SGname=-csye6225-webapp
SGname=$sn1$SGname
echo ""

Profiler=$(aws iam list-instance-profiles --query InstanceProfiles[].{InstanceProfileName:InstanceProfileName} --output text)
echo $Profiler

ec2Name=$(aws deploy get-deployment-group --application-name CSYE6225CodeDeployApplication \
 --deployment-group-name Codedeploy_groupname --query deploymentGroupInfo.ec2TagFilters[].{Value:Value} --output text)
echo $ec2Name

#====================================================================================================
# Creating a key-pair for ec2 instance
#====================================================================================================

exist=$(aws ec2 describe-key-pairs --query KeyPairs[].{KeyName:KeyName} --output text 2>&1)
if [[ -z "$exist" ]]
then
  echo "No Keypair exist. Please provide name to the keypair for ec2 instances"
  read key
  aws ec2 create-key-pair --key-name $key --query 'KeyMaterial' --output text  > $key.pem 2>&1
  chmod 400 $key.pem 2>&1
else
  echo "we have existing keypair."
  echo "$exist"
fi
echo ""

keypair=$(aws ec2 describe-key-pairs --query KeyPairs[].{KeyName:KeyName} --output text 2>&1)
echo "$keypair is used for ec2 server login"
echo ""

#====================================================================================================
# Obtaining Hosted Zone ID and zones
#====================================================================================================
ID=$(aws route53 list-hosted-zones --query HostedZones[].{Id:Id} --output text|cut -d"/" -f3 2>&1)
echo "Route53 Hosted Id is: $ID"
echo ""

HostedZoneName=$(aws route53 list-hosted-zones --query HostedZones[].{Name:Name} --output text | sed 's/.$//' 2>&1)
echo "Route53 Hosted Name is: $HostedZoneName"
echo ""

#====================================================================================================
# Obtaining VPC Id
#====================================================================================================
vpc_Id=$(aws ec2 describe-vpcs   --query 'Vpcs[*].{VpcId:VpcId}' --filters Name=tag:Name,Values=$sn1-csye6225-vpc Name=is-default,Values=false --output text  2>&1)
echo "Vpc id is: $vpc_Id"

#====================================================================================================
#Creation of the stack using Parameter File
#====================================================================================================

create=$(aws cloudformation create-stack --stack-name $sn --template-body file://csye6225-cf-application.json --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=KeyName,ParameterValue=$keypair ParameterKey=SubnetId,ParameterValue=$SubnetId ParameterKey=SubnetId1,ParameterValue=$SubnetId1 \
    ParameterKey=HostedZone,ParameterValue=$HostedZoneName ParameterKey=SSHLocation,ParameterValue=0.0.0.0/0 ParameterKey=VPC,ParameterValue=$vpc_Id \
    ParameterKey=HashKeyElementName,ParameterValue=EmailId ParameterKey=DBUser,ParameterValue=csye6225master ParameterKey=SubnetId2,ParameterValue=$SubnetId2 \
    ParameterKey=DBInstanceIdentifier,ParameterValue=csye6225-spring2018 ParameterKey=DBName,ParameterValue=csye6225 ParameterKey=Subnetgroupname,ParameterValue=$subname1 \
    ParameterKey=TableName,ParameterValue=csye6225 ParameterKey=S3Bucket,ParameterValue=$HostedZoneName.csye6225.com \
    ParameterKey=InsProfile,ParameterValue=$Profiler ParameterKey=Ec2Name,ParameterValue=$ec2Name ParameterKey=DBPassword,ParameterValue=csye6225password)

if [ $? -ne "0" ]
then
  echo "Creation of $sn stack failed...."
  exit 1
else
  echo "Creation of $sn is in progress......"
fi

#====================================================================================================
# Waiting for the stack to get created completely
#====================================================================================================

echo Stack in progress.....
Success=$(aws cloudformation wait stack-create-complete --stack-name $sn)

if [[ -z "$Success" ]]
then
  echo "$sn stack is created successfully. Printing output..."
else
  echo "Creation of $sn stack failed. Printing error and exiting....."
  echo "$Success"
  exit 1
fi