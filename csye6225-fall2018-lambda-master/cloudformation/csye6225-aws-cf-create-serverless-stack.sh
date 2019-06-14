#!/bin/bash
#====================================================================================================
# Synopsis: This script is used to create CentOS ec2 instances with security group and Route 53
# in CloudFormation Stack
#====================================================================================================
# Creation of Elastic Compute Cloud stacks
#====================================================================================================
echo "Enter stack name"
read serverless
echo ""

#====================================================================================================
# Validating the CloudFormation Template
#====================================================================================================

Valid=$(aws cloudformation  validate-template --template-body file://csye6225-cf-serverless.json)
if [ $? -ne "0" ]
then
  echo "$Valid"
  echo "$serverless Template file to build infrastructure is NOT VALID....."
  exit 1
else
  echo " Proceed ahead. CloudFormation Template is VALID......"
  echo ""
fi

#====================================================================================================
# Obtaining Lambda Bucket and File name from the bucket
#====================================================================================================
# To get endpoint
LambdaBucket=$(aws s3 ls | cut -d" " -f3|grep lambda)
echo $LambdaBucket $'\n'

s3key=$(aws s3api list-objects --bucket $LambdaBucket --query 'Contents[].{Key: Key}' --output text|grep lam)
echo "Object name in s3bucket = $s3key" $'\n'

HostedZoneName=$(aws route53 list-hosted-zones --query HostedZones[].{Name:Name} --output text | sed 's/.$//' 2>&1)
echo "Route53 Hosted Name is: $HostedZoneName"
echo ""

#====================================================================================================
# Obtaining Role and Email Address for Lambda
#====================================================================================================
Role=$(aws iam get-role --role-name lambda_Dynamodb_SES --query Role.{Arn:Arn} --output text)
echo "Role= $Role" $'\n'


#====================================================================================================
#Creation of the stack using Parameter File
#====================================================================================================

create=$(aws cloudformation create-stack --stack-name $serverless --template-body file://csye6225-cf-serverless.json --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=LambdaRole,ParameterValue=$Role ParameterKey=TableName,ParameterValue=csye6225 ParameterKey=s3Object,ParameterValue=$s3key \
  ParameterKey=Mail,ParameterValue=noreply@$HostedZoneName ParameterKey=LambdaFunctionName,ParameterValue=MyFunction ParameterKey=SSHLocation,ParameterValue=0.0.0.0/0 ParameterKey=LambdaBucket,ParameterValue=$LambdaBucket)

if [ $? -ne "0" ]
then
  echo "Creation of $serverless stack failed...."
  exit 1
else
  echo "Creation of $serverless is in progress......"
fi

#====================================================================================================
# Waiting for the stack to get created completely
#====================================================================================================

echo Stack in progress.....
Success=$(aws cloudformation wait stack-create-complete --stack-name $serverless)

if [[ -z "$Success" ]]
then
  echo "$serverless stack is created successfully. Printing output..."
else
  echo "Creation of $serverless stack failed. Printing error and exiting....."
  echo "$Success"
  exit 1
fi