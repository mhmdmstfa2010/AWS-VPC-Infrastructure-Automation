# AWS-VPC-Infrastructure-Automation

This project is part of the [AWS DevOps in 90 Days](https://cloudnativebasecamp.com/courses/aws-devops-90/) course by [Ahmed Metwally](https://cloudnativebasecamp.com/) at CloudNativeBaseCamp.

## Task Overview

This task focuses on automating AWS VPC infrastructure creation using Bash scripting, covering fundamental networking concepts in AWS.

## Infrastructure Components

The script creates the following AWS resources:
- 1 VPC with CIDR block `10.0.0.0/16`
- 2 Public subnets (10.0.1.0/24 and 10.0.2.0/24) in different AZs
- 2 Private subnets (10.0.3.0/24 and 10.0.4.0/24) in different AZs
- 1 Internet Gateway (IGW)
- Route tables with proper associations

## Learning Objectives

This task helps students:
1. Understand AWS VPC fundamentals
2. Automate infrastructure provisioning with Bash
3. Work with AWS CLI
4. Implement idempotent infrastructure scripts
5. Manage AWS networking components

## Prerequisites

- AWS CLI installed and configured
- AWS IAM permissions for VPC management
- Basic Bash scripting knowledge

## Usage

```bash
chmod +x vpc-task.sh
./vpc-task.sh

![Infar Diagram](https://github.com/mhmdmstfa2010/AWS-VPC-Infrastructure-Automation/blob/main/VPC.png)
