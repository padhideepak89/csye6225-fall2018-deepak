# CREATION OF VPC -
----------------------------------------------------------------------------------------------------
# SYNOPSIS
    Automates the creation of a custom IPv4 VPC, having public subnet, Internet
    gateway attached to VPC and Route tables using Shell Scripting

# DESCRIPTION
    This shell script leverages the AWS Command Line Interface (AWS CLI) to
    automatically create a custom VPC.
-----------------------------------------------------------------------------------------------------
# Steps to creation of VPC using Shell Scripting
1. Created a customized VPC with user providing the name of the VPC
2. Created Subnets, Route-Table and Internet Gateway connected to VPC
3. 3 Public and 3 Private subnet is created in VPC
4. Public subnet is associated with route table having Internet Gateway with IP Address as 0.0.0.0/0

-----------------------------------------------------------------------------------------------------
# DELETION OF VPC
-----------------------------------------------------------------------------------------------------
# SYNOPSIS
    Automates the Deletion of a custom IPv4 VPC, having public subnet, Internet
    gateway attached to VPC and Route tables

# DESCRIPTION
    This shell script leverages the AWS Command Line Interface (AWS CLI) to
    automatically delete a custom VPC.
-----------------------------------------------------------------------------------------------------
# Steps to creation of VPC using Shell Scripting
1. Disassociation of public subnet from Route-tables
2. Deleting the subnets
3. Deleting the route 0.0.0.0 from Route-table and then deleting route-tables
4. Detaching Internet gateway from VPC
5. Detaching Internet Gateway and finally VPC
-----------------------------------------------------------------------------------------------------
