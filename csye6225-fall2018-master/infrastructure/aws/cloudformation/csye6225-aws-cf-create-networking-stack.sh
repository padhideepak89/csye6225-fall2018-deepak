#====================================================================================================
# Synopsis: This script is used to create Custom VPC having Route-Table, Internet Gateway 
# and Subnet in CloudFormation Stack
#====================================================================================================
#Displaying the stacks
#====================================================================================================
echo Enter stack Name
read StackName

#====================================================================================================
#Validating the CloudFormation Template
#====================================================================================================
Valid=$(aws cloudformation  validate-template --template-body file://csye6225-cf-networking.json)
if [ $? -ne "0" ]
then
  echo $Valid
  echo "$StackName Template file to build infrastructure is NOT VALID....."
  exit 1
else
  echo " Proceed ahead. CloudFormation Template is VALID......"
fi

#====================================================================================================
#Creation of the stack using Parameter File
#====================================================================================================
echo Creating Stack.....
Create=$(aws cloudformation create-stack --stack-name $StackName --template-body file://csye6225-cf-networking.json --parameters file://Parameter.json)

#====================================================================================================
# Waiting for the stack to get created completely
#====================================================================================================

echo Stack in progress.....
Success=$(aws cloudformation wait stack-create-complete --stack-name $StackName)

if [[ -z "$Success" ]]
then
  echo "$StackName stack is created successfully. Printing output..."
else
  echo "Creation of $StackName stack failed. Printing error and exiting....."
  echo "$Success"
  exit 1
fi
