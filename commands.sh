# 1. Login AWS

aws configure

AWS Access Key ID [None]: "Sua chave de acesso"
AWS Secret Access Key [None]: "Sua chave secreta"
Default region name [None]: us-east-1
Default output format [None]: json

#2. Gerar chave publica

ssh-keygen -m PEM -f mykey.pem
ssh-keygen -y -f mykey.pem > mykey.pem.pub

aws ec2 import-key-pair --key-name publickey --public-key-material $(openssl enc -base64 -A -in mykey.pem.pub)

#3 Criando Security Group e liberando portas

aws ec2 create-security-group --group-name MeuSG --description "SG publico" --vpc-id "Seu VPC ID"

aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 111 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol udp --port 111 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 2049 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol udp --port 2049 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 80 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 443 --cidr 0.0.0.0/0 