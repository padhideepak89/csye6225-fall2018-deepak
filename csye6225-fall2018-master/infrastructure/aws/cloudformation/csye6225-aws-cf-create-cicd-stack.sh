#!/bin/bash
#====================================================================================================
# Synopsis: This script is used to create CentOS ec2 instances with security group and Route 53
# in CloudFormation Stack
#====================================================================================================
# Creation of Elastic Compute Cloud stacks
#====================================================================================================
echo "Enter Stack Name for the creation of CI/CD Stack"
read sn
echo ""

#====================================================================================================
# Validating the CloudFormation Template
#====================================================================================================

Valid=$(aws cloudformation  validate-template --template-body file://csye6225-cf-cicd.json)
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
# Obtaining Hosted Zone ID and zones
#====================================================================================================
ID=$(aws route53 list-hosted-zones --query HostedZones[].{Id:Id} --output text|cut -d"/" -f3 2>&1)
echo "Route53 Hosted Id is: $ID"
echo ""

HostedZoneName=$(aws route53 list-hosted-zones --query HostedZones[].{Name:Name} --output text | sed 's/.$//' 2>&1)
echo "Route53 Hosted Name is: $HostedZoneName"
echo ""

HostedZoneName1=$(aws route53 list-hosted-zones --query HostedZones[].{Name:Name} --output text)
com="csye6225.com"
BucketName=$HostedZoneName1$com

#====================================================================================================
#Creation of the Lambda bucket and uploading file
#====================================================================================================
echo "Validating/ Creating a bucket for lambda"
echo ""
Validate=$(aws s3 ls | grep lambda)
if [[ -z "$Validate" ]]
then
  echo "lambda.$HostedZoneName1$com does not exist. Creating lambda.$HostedZoneName1$com bucket"
  echo ""
  aws s3 mb s3://lambda.$HostedZoneName1$com --region us-east-1
  echo ""
  aws s3 cp ./lamdafunction-1.0-SNAPSHOT.zip s3://lambda.$HostedZoneName1$com
  echo ""
else
  echo "lambda.$HostedZoneName1$com does exist. Checking file is present or not"
  echo ""
  File=$(aws s3 ls s3://lambda.$HostedZoneName1$com)
  if [[ -z "$File" ]]
  then
    echo "Bucket is empty. Please uplod your lambda file. Uploading"
    echo ""
    aws s3 cp ./lamdafunction-1.0-SNAPSHOT.zip s3://lambda.$HostedZoneName1$com
  else
    echo "File is not empty. File is present"
  fi
fi

#====================================================================================================
#Creation of the stack using Parameter File
#====================================================================================================
export TravisUser=travis
create=$(aws cloudformation create-stack --stack-name $sn --template-body file://csye6225-cf-cicd.json --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=DeployBucket,ParameterValue=code-deploy.$HostedZoneName.csye6225.com \
  ParameterKey=TravisUser,ParameterValue=$TravisUser ParameterKey=AttachBucket,ParameterValue=$BucketName)

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
  echo "$StackName stack is created successfully. Printing output..."
else
  echo "Creation of $StackName stack failed. Printing error and exiting....."
  echo "$Success"
  exit 1
fi
