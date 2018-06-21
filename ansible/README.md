Jenkins Ansible Playbooks
----------------------

### Playbook Tasks:

- 1 x VPC with 3 x public VPC subnets in differrent AZ zones
- AWS key pair if not existing
- security groups
- ASG
- ELB
- Install Jenkins service

All informations about VPC, Jenkins, ELB, ASG are defined in their respective roles for both variables and tasks.

### Requirements:

- Ansible
- boto3

### AWS credentials:

Then add the following:
```shell
[Credentials]
aws_access_key_id = <your_access_key_here>
aws_secret_access_key = <your_secret_key_here>
```

### To use this Role:

Give the correct path to the SSH key in ansible.cfg file, for example:
```
[ssh_connection]
ssh_args = -i ./ssh_key/aws-jenkins-private.pem
```.

Edit the vars files inside the `vars` directory as per your requirement, for example `vpc.yml` file inside the `vars` directory:
```yaml
---
 # Variables for VPC
 vpc_name: iTMethods
 vpc_region: us-east-1
 vpc_cidr_block: 172.25.0.0/16
 public_cidr_1: 172.25.10.0/24
 public_az_1: "{{ vpc_region }}a"
 public_cidr_2: 172.25.20.0/24
 public_az_2: "{{ vpc_region }}b"
 private_cidr: 172.25.30.0/24
 private_az: "{{ vpc_region }}c"

 #
 # Subnets Defination for VPC
 vpc_subnets:
   - cidr: "{{ public_cidr_1 }}" # Public Subnet-1
     az: "{{ public_az_1 }}"
     resource_tags: { "Name":"{{ vpc_name }}-{{ public_az_1 }}-public-subnet" }
   - cidr: "{{ public_cidr_2 }}" # Public Subnet-2
     az: "{{ public_az_2 }}"
     resource_tags: { "Name":"{{ vpc_name }}-{{ public_az_2 }}-public-subnet" }
   - cidr: "{{ private_cidr }}" # Private Subnet
     az: "{{ private_az }}"
     resource_tags: { "Name":"{{ vpc_name }}-{{ private_az }}-private-subnet" }

 #
 # Routing Table for Public Subnet
 public_subnet_rt:
   - subnets:
       - "{{ public_cidr_1 }}"
       - "{{ public_cidr_2 }}"
     routes:
       - dest: 0.0.0.0/0
         gw: igw
```

After editing all the vars files as per requirements, run this command:
```shell
export AWS_PROFILE=Credentials
export AWS_REGION=us-east-1
ansible-playbook -i hosts jenkins.yml
```
