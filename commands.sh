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

#3. Criando Security Group e liberando portas

aws ec2 create-security-group --group-name MeuSG --description "SG publico" --vpc-id "Seu VPC ID"

aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 111 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol udp --port 111 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 2049 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol udp --port 2049 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 80 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 443 --cidr 0.0.0.0/0 

#4. Criando instancia Amazon Linux 2

aws ec2 run-instances \
    --image-id ami-0d191299f2822b1fa \ # ID da imagem do Amazon Linux 2
    --instance-type t3.small \          # Tipo de instância t3.small
    --key-name "SUA KEY PAIR" \                  # Nome da chave SSH
    --subnet-id "SUBNET ID" \       # ID da subnet onde a instância será lançada
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":16,\"VolumeType\":\"gp2\"}}]" \  # Configuração do disco
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=NFS}]'  # Tags para identificar a instância

#5. Gerar 1 elastic IP e anexar à instância EC2

aws ec2 allocate-address --domain "SEU VPC_ID" #Gera um Elatic IP

aws ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text #coleta o ID da suas instancias

aws ec2 associate-address --instance-id "SUA INSTANCE_ID" --allocation-id "SEU ELASTIC iP_ID" #Associa a instancia