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

#CONFIGURANDO NFS E APACHE

#1. Baixando e configurando NFS.

sudo yum update 
sudo yum install nfs-utils

#configurando diretório

sudo mkdir -p /mnt/nfs_srver
sudo chown nfsnobody:nfsnobody /mnt/nfs_server

echo "/mnt/nfs_server *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a #atualiza as exportações NFS no seu sistema

sudo systemctl enable nfs-server #habilita o nfs-server
sudo systemctl start nfs-server #inicia o nfs-server

sudo mkdir /mnt/nfs_server/erivelton
sudo chown ec2-user:ec2-user /mnt/nfs_server/erivelton

#2. Instalando apache

sudo yum install httpd
sudo systemctl start httpd
sudo systemctl enable httpd

nano monitor_apache.sh #criando script

chmod +x monitor_apache.sh #tornando o arquivo executável

# 3. Automatizando Script

crontab -e #editando crontab
*/5 * * * * /home/ec2-user/monitor_apache.sh #automatizando script

# 4. Criando Alias para o diretório NFS

sudo nano /etc/httpd/conf.d/nfs_logs.conf
