#!/bin/bash
#====================================================================================================
# Synopsis: This script is used to delete the stack consisting lambda and SNS
#====================================================================================================
# Checking which stacks needs to be deleted
#====================================================================================================

StackList=$(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_IN_PROGRESS CREATE_IN_PROGRESS --query 'StackSummaries[].StackName' --output text )
if [[ -z "$StackList" ]]
then
  echo "There is no Stack available to delete" 
  exit 1
else
  echo "Enter Networking stack Name to be deleted from the list"
  echo $StackList
  read StackName
  echo "Deleting the stack $StackName"
fi



#====================================================================================================
# Deleting the stack
#====================================================================================================

Delete=$(aws cloudformation delete-stack --stack-name $StackName)
if [ $? -ne "0" ]
then
  echo "$StackName stack is not deleted....."
  echo "$Delete"
  exit 1
else
  echo "Deletion in Progress....."
fi
#====================================================================================================
# Waiting till the stacks gets deleted
#====================================================================================================

Success=$(aws cloudformation wait stack-delete-complete --stack-name $StackName)
if [[ -z "$Success" ]]
then
  echo "$StackName Networking stack is deleted successfully"
else
  echo "Deletion of $StackName stack failed."
  echo "$Success"
  exit 1
fi