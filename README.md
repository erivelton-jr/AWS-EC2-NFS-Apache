# Criando Instância EC-2

#### Criando instância via terminal

<div>Neste repositório irei mostrar o proceso de criação de uma instância ec2 </div>

--- 

#### 1. Logando no terminal.

* <div>Para Logar iremos fazer o seguinte comando: </div>

```bash
aws configure

AWS Access Key ID [None]: "Sua chave de acesso"
AWS Secret Access Key [None]: "Sua chave secreta"
Default region name [None]: us-east-1
Default output format [None]: json/text or default[None]
```

#### 2. Gerar uma chave pública.

Para gerar uma chave pública precisamos primeiro gerar uma privada. Para isso iremos utilizar o `ssh-keygen`:

```bash
ssh-keygen -m PEM -f mykey.pem
```
Agora iremos criar uma chave pública a partir da chave privada.
```bash
ssh-keygen -y -f mykey.pem > mykey.pem.pub
```
Agora que criamos uma chave publica ssh, importá-la para o AWS:

```bash
aws ec2 import-key-pair --key-name publickey --public-key-material $(openssl enc -base64 -A -in mykey.pem.pub)
```

#### 3. Criando Security Group.

Iremos criar um SecurityGroup e liberar as portas de comunicação para acesso público: 
* TCP: 22
* TCP e UDP: 111
* TCP/UDP: 2049 
* TCP: 80
* TCP: 443.

```bash
aws ec2 create-security-group --group-name MeuSG --description "SG publico" --vpc-id "Seu VPC ID"

aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 111 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol udp --port 111 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 2049 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol udp --port 2049 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 80 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id seu_group_id --protocol tcp --port 443 --cidr 0.0.0.0/0 
```

#### 4. Criando Intância Amazon Linux 2
Agora irei criar uma instância EC2 com o sistema operacional Amazon Linux 2 (Família t3.small, com 16 GB SSD);
```bash
aws ec2 run-instances \
    --image-id ami-0d191299f2822b1fa \ # ID da imagem do Amazon Linux 2
    --instance-type t3.small \          # Tipo de instância t3.small
    --key-name "SUA KEY PAIR" \                  # Nome da chave SSH
    --subnet-id "SUBNET ID" \       # ID da subnet onde a instância será lançada
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":16,\"VolumeType\":\"gp2\"}}]" \  # Configuração do disco
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=NFS}]'  # Tags para identificar a instância
```
#### 5. Gerar 1 elastic IP e anexar à instância EC2

Vamos pegar o id da instancia criada e anexar ao elastic ip que iremos criar.

```bash
aws ec2 allocate-address --domain "SEU VPC_ID" #Cria Elastic IP

aws ec2 associate-address --instance-id "SUA INSTANCE_ID" --allocation-id "SEU ELASTIC iP_ID" #Associa a instancia
```
****
# Configurando NFS e Apache

Agora que configuramos a Instancia, iremos configurar o NFS e o Apache.

#### 1. Baixando e configurando NFS.

```bash
sudo yum update -y
sudo yum -y install nfs-utils
```

Depois que instalar, vamos configurar o diretório de exportação

```bash
    sudo mkdir -p /mnt/nfs_srver
    sudo chown nfsnobody:nfsnobody /mnt/nfs_server
```
Esse comando cria o diretório `/mnt/nfs_share` e altera a propriedade do diretório para o usuário `nfsnobody`e o grupo `nfsnobody`. 
* _Isso é comum já que este é um servidor publico, onde em diretórios compartilhados onde a propriedade individual não é necessária ou desejada._

```bash
echo "/mnt/nfs_server *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a #atualiza as exportações NFS no seu sistema
```
todo o comando configura o compartilhamento NFS no diretório `/mnt/nfs_server` permitindo acesso de leitura e escrita a qualquer host que se conecte, força a sincronização de dados e desabilita a verificação de subárvore para potencialmente melhorar o desempenho.

Após isso, só habilitar e iniciar o `nfs-server`
```bash
sudo systemctl enable nfs-server
sudo systemctl start nfs-server
```
Feito isso, irei criar um diretório detro do NFS FileSystem
```bash
sudo mkdir /mnt/nfs_server/erivelton
sudo chown ec2-user:ec2-user /mnt/nfs_server/erivelton
```
#### 2. Instalando apache

```bash
sudo yum install httpd
sudo systemctl start httpd
sudo systemctl enable httpd
```

#### 3. Criando script

```bash
nano monitor_apache.sh
```

```bash
#!/bin/bash

STATUS=$(systemctl is-active httpd)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
DIRECTORY="/mnt/nfs_server/erivelton"

if [ "$STATUS" == "active" ]; then
    echo "$TIMESTAMP - httpd - ONLINE - Apache está funcionando" >> "$DIRECTORY/apache_status_online.log"
else
    echo "$TIMESTAMP - httpd - OFFLINE - Apache não está funcionando" >> "$DIRECTORY/apache_status_offline.log"
fi
```

```bash
chmod +x monitor_apache.sh #tornando o arquivo executável
```

#### 4. Automatizando Script

```bash
crontab -e #editando crontab
```
Adicionando seguinte linha no crotab
```bash
*/5 * * * * /home/ec2-user/monitor_apache.sh
```
Esse comando prepara a execução automatizada do script a cada 5 minutos.

#### 5. Criando Alias para o diretório NFS

```bash
sudo nano /etc/httpd/conf.d/nfs_logs.conf
```
Agora, basta adicionar o seguinte comando:
```bash
Alias /nfs_logs /mnt/nfs_server/erivelton

<Directory /mnt/nfs_server/erivelton>
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
```
* Para acessar os logs, basa digitar `http://seu_ip/nfs_logs`
----
**Importante:** Desligue a máquina quando não for utilizar ⚠ 
