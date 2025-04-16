#!/bin/bash 
REGION="eu-north-1"
# check if there vpc
vpc_check=$(aws ec2 describe-vpcs  --region $REGION --filters Name=tag:Name,Values=DevOps-test | grep -oP '(?<="VpcId": ")[^"]*')
if [ -z "$vpc_check" ]; then

  # create vpc 10.0.0.0/16 
  vpc_result=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --region $REGION \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=DevOps-test}]' \
    --output json)

  echo $vpc_result

  vpc_id=$(echo $vpc_result | grep -oP '(?<="VpcId": ")[^"]*')

  echo $vpc_id

  if [ -z "$vpc_id" ]; then
    echo "Error in creating the vpc"
    exit 1
  fi

  echo "VPC created"

else
  echo "VPC already exists"
  vpc_id=$vpc_check
  echo $vpc_id
fi

# create subnet
create_subnet()
{
  # subnet num = $1 az = $2 , pub or private = $3 
  sub_check=$(aws ec2 describe-subnets --region $REGION --filters Name=tag:Name,Values=DevOps-test-$3-sub-$1 | grep -oP '(?<="SubnetId": ")[^"]*')
  if [ -z "$sub_check" ]; then
    echo "subnet $1 will be created"

    sub_result=$(aws ec2 create-subnet \
      --vpc-id $vpc_id \
      --cidr-block 10.0.$1.0/24 \
      --availability-zone eu-north-1$2 \
      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=DevOps-test-$3-sub-$1}]" \
      --output json)

    echo $sub_result

    sub_id=$( echo $sub_result | grep -oP '(?<="SubnetId": ")[^"]*')
    
    if [ -z "$sub_id" ]; then
      echo "Error in creating subnet $1"
      exit 1
    fi
    echo $sub_id

  else
    echo "subnet $1 already exist "
    sub_id=$sub_check
    echo $sub_id
  fi
}

create_subnet 1 a public
sub1_id=$sub_id

create_subnet 2 b public
sub2_id=$sub_id

create_subnet 3 a private
sub3_id=$sub_id

create_subnet 4 b private
sub4_id=$sub_id

# create igw for public subnets
igw_check=$(aws ec2 describe-internet-gateways  --filters Name=tag:Name,Values=DevOps-test-igw | grep -oP '(?<="InternetGatewayId": ")[^"]*') 
if [ -z "$igw_check" ]; then
  echo "Internet Gateway will be created"
  igw_result=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=DevOps-test-igw}]' \
    --output json)
  echo $igw_result
  igw_id=$( echo $igw_result | grep -oP '(?<="InternetGatewayId": ")[^"]*' )
  if [ -z "$igw_id" ]; then
    echo "Error in creating internet gateway" 
    exit 1
  fi 
  echo $igw_id
  
  # Attach the IGW to the VPC
  echo "Attaching IGW to VPC..."
  aws ec2 attach-internet-gateway \
    --internet-gateway-id $igw_id \
    --vpc-id $vpc_id
else 
  echo "Internet gateway already exist"
  igw_id=$igw_check
  echo $igw_id
  
  # Check if IGW is attached to our VPC
  igw_attach=$(aws ec2 describe-internet-gateways --internet-gateway-ids $igw_id | grep -oP '(?<="VpcId": ")[^"]*')
  if [ "$igw_attach" != "$vpc_id" ]; then
    echo "Attaching existing IGW to our VPC..."
    aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
  fi
fi

# create public route table 
pub_rt_check=$( aws ec2 describe-route-tables --filters Name=tag:Name,Values=DevOps-test-pub-rt | grep -oP '(?<="RouteTableId": ")[^"]*' | uniq ) 

if [ -z "$pub_rt_check" ]; then
  echo "Public Route table will be created"
  pub_rt_result=$(aws ec2 create-route-table \
    --vpc-id $vpc_id \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=DevOps-test-pub-rt}]' \
    --output json)
  echo $pub_rt_result
  pub_rt_id=$( echo $pub_rt_result | grep -oP '(?<="RouteTableId": ")[^"]*' )
  if [ -z "$pub_rt_id"  ]; then
    echo "Error in creating Public Route Table" 
    exit 1
  fi 
  echo "public route table created"
  
  # create public route 
  echo "Creating default route to IGW..."
  route_result=$(aws ec2 create-route --route-table-id $pub_rt_id \
      --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id | grep -oP '(?<="Return": ")[^"]*')
  echo $route_result
  if [ "$route_result" != "true" ]; then
      echo "public route creation failed"
      exit 1
  fi
  echo "public route created"
else 
  echo "Public Route Table already exist"
  pub_rt_id=$pub_rt_check
fi
echo $pub_rt_id

# associate public route table to the public subnets
echo "Associating public subnets with public route table..."
aws ec2 associate-route-table --route-table-id $pub_rt_id --subnet-id $sub1_id
aws ec2 associate-route-table --route-table-id $pub_rt_id --subnet-id $sub2_id

# create private route table 
private_rt_check=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=DevOps-test-private-rt | grep -oP '(?<="RouteTableId": ")[^"]*' | uniq )

if [ -z "$private_rt_check" ]; then
  echo "Private Route table will be created"
  private_rt_result=$(aws ec2 create-route-table \
    --vpc-id $vpc_id \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=DevOps-test-private-rt}]' \
    --output json)
  echo $private_rt_result
  private_rt_id=$( echo $private_rt_result | grep -oP '(?<="RouteTableId": ")[^"]*' )
  if [ -z "$private_rt_id" ]; then
    echo "Error in creating Private Route Table" 
    exit 1
  fi 
  echo $private_rt_id
else 
  echo "Private Route Table already exist"
  private_rt_id=$private_rt_check
fi
echo $private_rt_id

# associate private route table to the private subnets
echo "Associating private subnets with private route table..."
aws ec2 associate-route-table --route-table-id $private_rt_id --subnet-id $sub3_id
aws ec2 associate-route-table --route-table-id $private_rt_id --subnet-id $sub4_id

echo "VPC setup completed successfully!"
