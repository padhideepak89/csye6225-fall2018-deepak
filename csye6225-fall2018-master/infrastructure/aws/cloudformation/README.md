------------------------------------------------------------------------------------------------------------------------------------------
# Creation of CloudFormation Stack using scripting
------------------------------------------------------------------------------------------------------------------------------------------
# Description: 

    AWS cloudFormation stack was created by programming json template. This json template will create Custom VPC, Subnets,
    Route-tables and Internet Gateway
------------------------------------------------------------------------------------------------------------------------------------------
# Steps to create CloudFormation template - Networking JSON file

 1. Created a JSON file containing Parameters, Resources and Output
 2. The template includes VPC with 3 Private subnet and 3 public subnet, Internet Gateway and Route Table
 3. Internet Gateway is attached with the Custom VPC
 4. Public subnets are associated with route-table containing Internet Gateway which makes them public

------------------------------------------------------------------------------------------------------------------------------------------
# Step to create Parameter JSON file
    
1.  This files contains all the IPv4 addresses of VPC, 6 Subnets, one internet gateway and Route table as parameters of the
    above Networking JSON file respectively. 
------------------------------------------------------------------------------------------------------------------------------------------ 
# Steps to create automated script to create stack

1. Accepted Stack name to be created from the user.
2. Created a Stack by extracting the Networking JSON and Parameter JSON file.
3. Wait to get the success message and verify in AWS Console if the Stack is created
------------------------------------------------------------------------------------------------------------------------------------------
# Deletion of CloudFormation Stack using scripting
------------------------------------------------------------------------------------------------------------------------------------------
#  Steps to create automated script to terminate Stack 

1. List the available Stacks present in CloudFormation and ask the user which Stack is to be deleted.
2. Read the Stack name and process the Deletion progress.
3. Wait to get the success message and the verify in AWS Console
----------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------

# Creation of Application Stack JSON file

----------------------------------------------------------------------------------------------------------------------------------------

1. This file contains the creation of EC2 instance along with the security groups (Security Group for Web Servers and Security Group for DB Servers) that is used to setup application resources. 

# Steps to create automated script to create application stack

1. Accepted Stack name to be created from the user
2. Created a Application Stack by extracting the Application JSON file and Parameters list.
3.  Wait to get the success message and verify in AWS Console if the Stack is created

----------------------------------------------------------------------------------------------------------------------------------------

# Deletion of CloudFormation Stack using scripting

----------------------------------------------------------------------------------------------------------------------------------------

#  Steps to create automated script to terminate Stack 

1. List the available Stacks present in CloudFormation and ask the user which Stack is to be deleted.
2. Read the Stack name and process the Deletion progress.
3. Wait to get the success message and the verify in AWS Console

----------------------------------------------------------------------------------------------------------------------------------------
