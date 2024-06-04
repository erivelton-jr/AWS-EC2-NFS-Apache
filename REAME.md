# Criando Instância EC-2

#### Criando instância via terminal

<div>Neste repositório irei mostrar o proceso de criação de uma instância ec2 </div>

--- 

#### 1. Logando no terminal.

* <div>Para Logar iremos fazer o seguinte comando: </div>

```
aws configure

AWS Access Key ID [None]: "Sua chave de acesso"
AWS Secret Access Key [None]: "Sua chave secreta"
Default region name [None]: us-east-1
Default output format [None]: json/text or default[None]
```

#### 2. Gerar uma chave pública.

Para gerar uma chave pública precisamos primeiro gerar uma privada. Para isso iremos utilizar o `ssh-keygen`:

```
ssh-keygen -m PEM -f mykey.pem
```
Agora iremos criar uma chave pública a partir da chave privada.
```
ssh-keygen -y -f mykey.pem > mykey.pem.pub
```
Agora que criamos uma chave publica ssh, importá-la para o AWS:

```
aws ec2 import-key-pair --key-name publickey\
 --public-key-material $(openssl enc -base64 -A -in mykey.pem.pub)
```

#### 3. Criando Security Group.

Iremos criar um SecurityGroup e liberar as portas de comunicação para acesso público: 
* TCP: 22
* TCP e UDP: 111
* TCP/UDP: 2049 
* TCP: 80
* TCP: 443.

```
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
