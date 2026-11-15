# 🏗️ Laboratorio Infraestructura como Código

Los puntos 1, 2, 3 y 4 son gratuitos; a partir del 5 se empieza a incurrir en gastos. Hay que usar siempre `terraform destroy` al terminar para no generar gastos innecesarios.

## Entorno que he usado y por qué

La idea era hacerlo todo contra AWS, pero mi cuenta nueva se quedó bloqueada pendiente de una verificación manual de AWS y no pude crear ningún recurso (está explicado en el ejercicio 1). Así que he simulado el entorno en local con LocalStack y Docker:

| Herramienta | Para qué | Por qué |
|---|---|---|
| Terraform 1.16 + provider AWS 6.x | Todo el código de los ejercicios | Es lo que pide el módulo. El código está escrito para AWS (región `eu-west-3`) y vale tal cual |
| [LocalStack](https://www.localstack.cloud/) (plan Hobby, gratuito) | Hacer de AWS en local con Docker | Así los `plan` y `apply` son de verdad, aunque la "nube" sea mi máquina |
| `localstack_override.tf` | Apuntar el provider a LocalStack | Terraform carga solo los `*_override.tf`, así que no toco `main.tf`. Para usar AWS basta con borrar este fichero |
| Contenedor `ec2-sim` (Amazon Linux 2023 + SSH) | Hacer de instancia EC2 en los ejercicios 6, 7 y 8 | En el plan gratuito de LocalStack las EC2 son simuladas: no arrancan ninguna máquina, así que no hay SSH, Docker ni NGINX. El contenedor lleva el mismo sistema que la AMI y se entra con la clave del key pair |

Lo que he podido hacer de verdad con LocalStack: los ejercicios 1 a 5, la creación de la instancia del 6, el `user_data` del 7, el output del 8 y el refactor con el módulo del 9. Lo simulado con el `ec2-sim`: el SSH del 6, la instalación de Docker del 7 y el NGINX del 8. En cada ejercicio indico qué parte es simulada.

Para montar estos entornos (LocalStack, el override del provider y el contenedor que hace de EC2) y para entender algunos de los errores que me fueron saliendo por el camino he tenido que tirar de IA para poder avanzar con los ejercicios.

## Terraform AWS

### Ejercicio 1. VPC

Crear una VPC (recurso VPC) que tenga acceso a internet.

#### 📋 Requisitos

- [x] Asignar un CIDR block para la VPC.
- [x] Elegir una región adecuada.

#### 🛠️ Resolución

Solución

Para la VPC uso el rango privado `10.0.0.0/16`, que deja unas 65.000 direcciones para ir cortando subnets más adelante (`10.0.1.0/24`, etc.). Como región elijo `eu-west-3` (París): está cerca, así que la latencia es baja para el SSH y el navegador, viene activada por defecto (la de España, `eu-south-2`, es opt-in) y tiene instancias free tier.

`06-iac/terraform/main.tf`:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "lab-vpc"
  }
}
```

Las credenciales no van en el código, Terraform las coge de `aws configure`. Para eso creo en IAM un usuario `terraform-lab` con `AdministratorAccess` y sus access keys, y no uso el usuario root. En `06-iac/.gitignore` dejo fuera la carpeta `.terraform/` y el state:

```
.terraform/
*.tfstate
*.tfstate.*
```

```bash
terraform init
terraform plan
terraform apply
```

El plan sale bien (`Plan: 1 to add`), pero el `apply` falla:

```
aws_vpc.main: Creating...
Error: creating EC2 VPC: operation error EC2: CreateVpc, https response error StatusCode: 403,
api error UnauthorizedOperation: You are not authorized to perform this operation.
User: arn:aws:iam::<cuenta>:user/terraform-lab is not authorized to perform: ec2:CreateVpc
on resource: arn:aws:ec2:eu-west-3:<cuenta>:vpc/* with an explicit deny in a service control policy
```

El usuario tiene `AdministratorAccess`, así que no es un permiso que falte. La clave está al final: *explicit deny in a service control policy*. Una SCP es una política que pone una organización de AWS por encima de las cuentas que contiene, y un deny explícito gana siempre, dan igual los permisos que tenga el usuario, incluso root. Mi cuenta, recién creada, estaba dentro de una organización gestionada por AWS.

Lo compruebo con llamadas que no crean nada:

```bash
aws ec2 create-vpc --dry-run --cidr-block 10.0.0.0/16 --region <region>
aws ec2 describe-vpcs --region eu-west-3
aws s3api list-buckets
```

Todo denegado: EC2 en todas las regiones que probé, incluso las lecturas, y también S3, Lambda y DynamoDB. Solo funcionaban IAM y STS. Durante más de dos semanas intento:

- Añadir más políticas al usuario: no cambia nada, la SCP está por encima de IAM.
- Pasar la cuenta del plan gratuito al de pago (antes creo un *Zero spend budget* para que me avise al primer céntimo): sigue igual.
- Abrir un caso en AWS Support (Cuenta y facturación): la respuesta no me carga en la consola y con el plan básico no tengo chat.

Al final veo que la verificación automática de la cuenta está parada esperando una verificación manual por parte de AWS, y mientras no la hagan la cuenta no puede usar ningún servicio.

Para no quedarme parado uso [LocalStack](https://www.localstack.cloud/), que emula AWS en local con Docker. Las versiones actuales ya no arrancan sin cuenta: el contenedor se para con `License activation failed` y pide un `LOCALSTACK_AUTH_TOKEN`. Me registro en el plan gratuito, guardo el token en la variable de entorno `LOCALSTACK_AUTH_TOKEN` y arranco el contenedor pasándosela sin valor, así Docker la coge de mi sesión y el token no queda escrito en el comando:

```bash
docker run -d --name localstack -p 4566:4566 -e LOCALSTACK_AUTH_TOKEN localstack/localstack
curl http://localhost:4566/_localstack/health
```

Para no tocar `main.tf` uso un fichero de override. Terraform carga solo cualquier fichero que acabe en `_override.tf` y lo mezcla con el resto, así que este redirige el provider a LocalStack y el día que tenga AWS basta con borrarlo:

`06-iac/terraform/localstack_override.tf`:
```hcl
provider "aws" {
  region                      = "eu-west-3"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    iam = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}
```

`test`/`test` son credenciales de mentira que acepta LocalStack, y al ir en el provider tienen prioridad sobre las de `aws configure`, así que las reales no salen de mi máquina.

Ahora el `apply` sí crea la VPC:

```
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 1s [id=vpc-7eb8e9f00248d1fbd]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

---

### Ejercicio 2. Internet gateway

#### 📋 Requisitos

- [x] Crear un recurso internet gateway y asociarlo a la VPC.

#### 🛠️ Resolución

Solución

La VPC por sí sola no tiene salida a internet; el internet gateway es la puerta. Lo asocio a la VPC referenciando su id, y con eso Terraform ya sabe que tiene que crear primero la VPC y después el gateway.

Añado a `main.tf`:
```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "lab-igw"
  }
}
```

En el plan la VPC no aparece porque ya existe y no cambia, solo se añade el gateway, y el `vpc_id` ya sale con el id real que Terraform tiene guardado en el state:

```
aws_vpc.main: Refreshing state... [id=vpc-7eb8e9f00248d1fbd]

  # aws_internet_gateway.main will be created
  + resource "aws_internet_gateway" "main" {
      + vpc_id   = "vpc-7eb8e9f00248d1fbd"
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

```
aws_internet_gateway.main: Creating...
aws_internet_gateway.main: Creation complete after 0s [id=igw-0dae058ec070b3428]
```

El gateway todavía no hace nada solo; en el ejercicio 3 la tabla de rutas es la que manda el tráfico hacia él.

---

### Ejercicio 3. Subnet con acceso a internet

Crear una subnet dentro de la VPC con acceso a internet.

#### 📋 Requisitos

- [x] Crear un recurso de subnet.
- [x] Crear un recurso de tabla de rutas.
- [x] Definir una ruta que envíe todas las IPs a la internet gateway.
- [x] Asociar la tabla de rutas con la subnet.

#### 🛠️ Resolución

Solución

Corto un `/24` de la VPC para la subnet, en una sola zona (`eu-west-3a`), y le pongo `map_public_ip_on_launch` para que las instancias que se lancen ahí reciban IP pública. Lo que la hace pública de verdad es la tabla de rutas: la ruta `0.0.0.0/0` (cualquier destino que no sea la propia VPC) sale por el internet gateway. Sin la asociación, la subnet usaría la tabla principal de la VPC, que no tiene esa ruta.

Añado a `main.tf`:
```hcl
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = "lab-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "lab-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

En el plan la ruta ya apunta al gateway del ejercicio anterior, y la asociación tiene `subnet_id` y `route_table_id` como `(known after apply)` porque dependen de dos recursos que todavía no existen:

```
  # aws_route_table.public will be created
      + route            = [
          + {
              + cidr_block                 = "0.0.0.0/0"
              + gateway_id                 = "igw-0dae058ec070b3428"
            },
        ]

  # aws_route_table_association.public will be created
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)

Plan: 3 to add, 0 to change, 0 to destroy.
```

En el apply se ve el orden: la subnet y la tabla se crean a la vez porque no dependen una de otra, y la asociación espera a que terminen las dos:

```
aws_route_table.public: Creating...
aws_subnet.public: Creating...
aws_route_table.public: Creation complete after 1s [id=rtb-035df5fac8de38dad]
aws_subnet.public: Creation complete after 10s [id=subnet-5cc303a164a0ecb88]
aws_route_table_association.public: Creating...
aws_route_table_association.public: Creation complete after 1s [id=rtbassoc-56ca90a649fdccc69]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

---

### Ejercicio 4. Security groups

#### 📋 Requisitos

- [x] Permitir tráfico en el puerto 80 para todas las IPs.
- [x] Permitir el puerto 22 solo para mi IP (opcional).

#### 🛠️ Resolución

Solución

El security group hace de firewall de la instancia: el 80 abierto a todo el mundo y el 22 solo para mi IP (`/32` es una sola dirección). También pongo la salida a todo, porque AWS la trae por defecto pero Terraform la quita si no está declarada, y la instancia tiene que poder bajarse Docker y la imagen de NGINX.

Mi IP no la escribo en el código: va en una variable y el valor en `terraform.tfvars`, que Terraform carga solo y que añado al `.gitignore` (`*.tfvars`) para que no acabe en el repo.

```bash
curl -s https://checkip.amazonaws.com
```

`06-iac/terraform/terraform.tfvars` (no se sube):
```hcl
my_ip = "<mi IP>"
```

Añado a `main.tf`:
```hcl
variable "my_ip" {
  description = "IP pública desde la que se permite SSH"
  type        = string
}

resource "aws_security_group" "web" {
  name        = "lab-web-sg"
  description = "HTTP para todos y SSH solo desde mi IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH desde mi IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lab-web-sg"
  }
}
```

`protocol = "-1"` es cualquier protocolo, por eso los puertos van de 0 a 0. En el plan se ve la variable ya sustituida en la regla del 22:

```
      + ingress                = [
          + {
              + cidr_blocks      = ["0.0.0.0/0"]
              + description      = "HTTP"
              + from_port        = 80
              + to_port          = 80
            },
          + {
              + cidr_blocks      = ["<mi IP>/32"]
              + description      = "SSH desde mi IP"
              + from_port        = 22
              + to_port          = 22
            },
        ]

Plan: 1 to add, 0 to change, 0 to destroy.
```

```
aws_security_group.web: Creating...
aws_security_group.web: Creation complete after 1s [id=sg-778239224e0f148da]
```

Si cambia la IP de casa (por ejemplo al reiniciar el router), en AWS real me quedaría sin SSH hasta actualizar el `tfvars` y volver a hacer `apply`.

---

### Ejercicio 5. Key pair

#### 📋 Requisitos

- [x] Crear un recurso key pair para poder acceder a una EC2.

#### 🛠️ Resolución

Solución

El `aws_key_pair` solo sube la clave pública; AWS la mete en el `authorized_keys` de la instancia al lanzarla. La clave la genero yo con `ssh-keygen` en vez de con el provider `tls` de Terraform, porque así la privada no acaba guardada en texto plano en el state: se queda solo en mi máquina.

```bash
mkdir ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/lab-ec2 -C "lab-ec2"
```

En Windows la carpeta `.ssh` no existía y `ssh-keygen` no la crea, así que el primer intento falló con `Saving key "C:\\Users\\...\\.ssh\\lab-ec2" failed: No such file or directory` hasta que la creé.

Añado a `main.tf`:
```hcl
resource "aws_key_pair" "lab" {
  key_name   = "lab-key"
  public_key = file(pathexpand("~/.ssh/lab-ec2.pub"))
}
```

`pathexpand` cambia el `~` por la carpeta de usuario, así no dejo mi ruta escrita en el código. En el plan sale la clave pública en claro, que es lo normal:

```
  # aws_key_pair.lab will be created
  + resource "aws_key_pair" "lab" {
      + fingerprint     = (known after apply)
      + key_name        = "lab-key"
      + public_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOo2UbMSCpQk1beczzzZJ1ZRUR5danEl9e/j3b1Fpzrz lab-ec2"
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

```
aws_key_pair.lab: Creating...
aws_key_pair.lab: Creation complete after 0s [id=lab-key]
```

---

### Ejercicio 6. Instancia EC2

Crear una instancia que se despliegue en la subnet creada. Importante: usar una AMI free tier.

#### 📋 Requisitos

- [x] Desplegar la instancia en la subnet.
- [x] Asociar el key pair a la instancia.
- [x] Conectarse por SSH (simulado, ver resolución).

#### 🛠️ Resolución

Solución

En vez de poner un id de AMI fijo, que cambia por región y con cada versión, la busco con un `data` source, que solo consulta y no crea nada. Mi primera idea era Ubuntu 24.04, filtrando por el owner de Canonical (`099720109477`) para que no se cuele una imagen de otro con el mismo nombre:

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}
```

Pero el plan falla:

```
Error: Your query returned no results. Please change your search criteria and try again.

  with data.aws_ami.ubuntu,
  on main.tf line 103, in data "aws_ami" "ubuntu":
```

LocalStack tiene un catálogo de AMIs simuladas y de Canonical solo trae la 14.04 y la 16.04:

```bash
aws --endpoint-url http://localhost:4566 ec2 describe-images --filters "Name=name,Values=*ubuntu*" \
  --query 'Images[].[ImageId,OwnerId,Name]' --output text
```
```
ami-1e749f67	099720109477	ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-20170727
ami-785db401	099720109477	ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-20170721
```

Así que cambio a Amazon Linux 2023, que es free tier, está en LocalStack y también en AWS, así que el código vale para los dos. El patrón deja fuera las variantes `minimal` y las de ARM. Con esta AMI el usuario de SSH es `ec2-user` y los paquetes van con `dnf`.

Añado a `main.tf`:
```hcl
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.lab.key_name

  tags = {
    Name = "lab-web"
  }
}
```

`t3.micro` es free tier. La IP pública no hace falta pedirla aquí porque ya la da la subnet con `map_public_ip_on_launch`.

```
data.aws_ami.al2023: Read complete after 0s [id=ami-0d38994be4bb7d667]
...
  # aws_instance.web will be created
      + ami                                  = "ami-0d38994be4bb7d667"
      + instance_type                        = "t3.micro"
      + key_name                             = "lab-key"
      + public_ip                            = (known after apply)
      + subnet_id                            = "subnet-5cc303a164a0ecb88"

Plan: 1 to add, 0 to change, 0 to destroy.
```

```
aws_instance.web: Creating...
aws_instance.web: Still creating... [00m10s elapsed]
aws_instance.web: Creation complete after 10s [id=i-55d8bbad9ce2981f6]
```

La instancia queda `running` en la subnet, con IP privada de la `10.0.1.0/24`, IP pública y el key pair:

```bash
aws --endpoint-url http://localhost:4566 ec2 describe-instances \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress,KeyName]' --output text
```
```
i-55d8bbad9ce2981f6	running	54.214.190.75	10.0.1.4	lab-key
```

Pero es una instancia simulada: LocalStack guarda sus datos y no arranca ninguna máquina, así que la IP es inventada y no hay nada a lo que hacer SSH. LocalStack tiene un modo en el que cada EC2 es un contenedor de verdad, así que lo pruebo recreando el contenedor con acceso al Docker de mi máquina:

```bash
docker rm -f localstack
docker run -d --name localstack -p 4566:4566 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e EC2_VM_MANAGER=docker \
  -e LOCALSTACK_AUTH_TOKEN \
  localstack/localstack
```

Como LocalStack no guarda nada al recrearlo, en el siguiente `apply` Terraform ve en el refresh que los recursos del state ya no existen y los vuelve a crear todos (`Apply complete! Resources: 8 added`). La instancia sale otra vez `running`, pero no aparece ningún contenedor nuevo y en los logs se ve que la licencia es la gratuita (`freemium`). Con el plan Hobby las EC2 solo se simulan.

Para hacer la parte del SSH de verdad monto un contenedor que hace de EC2, lo más parecido posible a la instancia: Amazon Linux 2023, el usuario `ec2-user` con sudo y sin contraseña, y mi clave pública en su `authorized_keys`, que es lo que hace AWS con el key pair al lanzar la instancia.

`06-iac/ec2-sim/Dockerfile`:
```dockerfile
FROM amazonlinux:2023

RUN dnf install -y openssh-server sudo shadow-utils procps-ng && dnf clean all \
 && useradd -m ec2-user && usermod -p '*' ec2-user \
 && echo "ec2-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ec2-user \
 && ssh-keygen -A

EXPOSE 22 80

CMD ["sh", "-c", "install -d -m 700 -o ec2-user -g ec2-user /home/ec2-user/.ssh && install -m 600 -o ec2-user -g ec2-user /tmp/key.pub /home/ec2-user/.ssh/authorized_keys && exec /usr/sbin/sshd -D -e"]
```

La clave pública se monta en `/tmp/key.pub` y al arrancar se copia con los permisos que exige `sshd` (700 la carpeta, 600 el fichero). Lo arranco en `--privileged` para poder tener Docker dentro en el ejercicio 7, y mapeo el 22 al 2222 y el 80 al 8080:

```bash
cd 06-iac/ec2-sim
docker build -t ec2-sim .
docker run -d --name ec2-sim --privileged -p 2222:22 -p 8080:80 \
  -v ~/.ssh/lab-ec2.pub:/tmp/key.pub:ro ec2-sim
ssh -i ~/.ssh/lab-ec2 -p 2222 ec2-user@localhost
```
```
The authenticity of host '[localhost]:2222 ([::1]:2222)' can't be established.
ED25519 key fingerprint is SHA256:pnkl7h1RdmDp254F40Ouf15P8erRVCkDbQP3wSorszc.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[localhost]:2222' (ED25519) to the list of known hosts.
   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___   https://aws.amazon.com/linux/amazon-linux-2023
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'
[ec2-user@eb7f37c0fcf2 ~]$
```

En AWS sería lo mismo cambiando el puerto y `localhost` por la IP pública de la instancia: `ssh -i ~/.ssh/lab-ec2 ec2-user@<ip pública>`.

---

### Ejercicio 7. Docker con user_data

#### 📋 Requisitos

- [x] Añadir una entrada en el `user_data` que instale Docker.

#### 🛠️ Resolución

Solución

El `user_data` es un script que la instancia ejecuta una sola vez, como root, en el primer arranque. En Amazon Linux 2023 Docker está en los repos oficiales; lo instalo, lo dejo arrancado y habilitado para cada reinicio, y meto a `ec2-user` en el grupo `docker` para no tener que usar `sudo`.

En el `aws_instance.web` de `main.tf`:
```hcl
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
  EOF
```

Como la instancia ya existía, Terraform intenta cambiarle el `user_data` en el sitio: la para, modifica el atributo y la vuelve a arrancar. LocalStack rechaza la modificación:

```
Error: updating EC2 Instance (i-b48a4b0195271af29) user data: modifying EC2 Instance (i-b48a4b0195271af29)
UserData attribute: operation error EC2: ModifyInstanceAttribute, https response error StatusCode: 400,
api error InvalidUserData.Malformed: Invalid BASE64 encoding of user data.
```

De todas formas cambiar el `user_data` de una instancia que ya existe no tiene sentido, porque no lo vuelve a ejecutar. Lo lógico es que si cambia se cree una instancia nueva, así que añado:

```hcl
  user_data_replace_on_change = true
```

Pero el siguiente `apply` solo cambia esa opción (`0 to add, 1 to change`) y no recrea nada. El `apply` que falló había dejado el state desincronizado: el provider llegó a parar la instancia y guardó el `user_data` nuevo en el state aunque LocalStack no lo tenía:

```bash
terraform state show aws_instance.web
aws --endpoint-url http://localhost:4566 ec2 describe-instance-attribute \
  --instance-id i-b48a4b0195271af29 --attribute userData --query 'UserData.Value' --output text
```
```
    instance_state                       = "stopped"
    public_ip                            = null
    user_data                            = <<-EOT
...
None
```

Como para Terraform ya no había diferencia, fuerzo que la recree:

```bash
terraform apply -replace="aws_instance.web"
```
```
aws_instance.web: Destroying... [id=i-b48a4b0195271af29]
aws_instance.web: Destruction complete after 10s
aws_instance.web: Creating...
aws_instance.web: Creation complete after 10s [id=i-99558ba3ad4217c5d]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
```

La instancia nueva está `running` y esta vez LocalStack sí tiene el script (lo guarda en base64):

```bash
aws --endpoint-url http://localhost:4566 ec2 describe-instance-attribute \
  --instance-id i-99558ba3ad4217c5d --attribute userData --query 'UserData.Value' --output text | base64 -d
```
```
#!/bin/bash
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user
```

Como en LocalStack el script no se ejecuta, lo lanzo a mano en el `ec2-sim`. La única diferencia es que el contenedor no tiene `systemd`, así que en vez de `systemctl` arranco `dockerd` en segundo plano:

```bash
sudo dnf install -y docker
sudo dockerd > /tmp/dockerd.log 2>&1 &
sudo usermod -aG docker ec2-user
exit
```

Vuelvo a entrar para que se aplique el grupo y Docker ya funciona sin `sudo`:

```bash
docker version
docker run --rm hello-world
```
```
Server:
 Engine:
  Version:          25.0.18
...
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

---

### Ejercicio 8. Output y NGINX

Para ver algo por HTTP tiene que haber algo sirviendo en el puerto 80.

#### 📋 Requisitos

- [x] Crear un output con la IP pública de la instancia.
- [x] Conectarse por SSH y desplegar un contenedor NGINX con Docker (simulado, en el `ec2-sim`).

#### 🛠️ Resolución

Solución

Con el output no tengo que buscar la IP en la consola, y como acabo de ver, cambia cada vez que se recrea la instancia.

Añado a `main.tf`:
```hcl
output "public_ip" {
  description = "IP pública de la instancia"
  value       = aws_instance.web.public_ip
}
```

No cambia nada de la infraestructura, solo aparece el output:

```bash
terraform apply
terraform output public_ip
```
```
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

public_ip = "54.214.181.202"
```
```
"54.214.181.202"
```

Para tener algo en el puerto 80, desde el SSH levanto un NGINX con el Docker del ejercicio anterior:

```bash
docker run -d --name nginx -p 80:80 nginx
docker ps
curl -s localhost | head -5
```
```
CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS         PORTS                               NAMES
a82f48195fe5   nginx     "/docker-entrypoint.…"   11 seconds ago   Up 9 seconds   0.0.0.0:80->80/tcp, :::80->80/tcp   nginx
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
```

El 80 del `ec2-sim` está mapeado al 8080 de mi máquina, así que en el navegador abro `http://localhost:8080` y sale la página de bienvenida de NGINX. En AWS sería `http://<public_ip>` con la IP del output, y llegaría porque el security group deja pasar el 80 a todo el mundo.

---

### Ejercicio 9. VPC Module

#### 📋 Requisitos

- [x] Refactorizar el código para que use el VPC Module.

#### 🛠️ Resolución

Solución

Sustituyo los cinco recursos de red que había escrito a mano (VPC, internet gateway, subnet, tabla de rutas y asociación) por el módulo oficial [`terraform-aws-modules/vpc/aws`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws). Con `public_subnets` ya crea él solo el gateway, la tabla y la ruta a `0.0.0.0/0`. Dejo explícito `enable_nat_gateway = false`: la NAT solo hace falta para subnets privadas y en AWS cuesta unos 30 $ al mes.

En `main.tf`, en lugar de los cinco recursos:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "lab-vpc"
  cidr = "10.0.0.0/16"

  azs                     = ["eu-west-3a"]
  public_subnets          = ["10.0.1.0/24"]
  map_public_ip_on_launch = true
  enable_dns_hostnames    = true

  enable_nat_gateway = false
}
```

Y lo que usaba esos recursos pasa a usar las salidas del módulo:
```hcl
resource "aws_security_group" "web" {
  ...
  vpc_id      = module.vpc.vpc_id
```
```hcl
resource "aws_instance" "web" {
  ...
  subnet_id              = module.vpc.public_subnets[0]
```

Hay que volver a hacer `init` para que se baje el módulo:

```bash
terraform init
```
```
Initializing modules...
Downloading registry.terraform.io/terraform-aws-modules/vpc/aws 6.7.3 for vpc...
- vpc in .terraform\modules\vpc
```

Para Terraform `aws_vpc.main` y `module.vpc.aws_vpc.this[0]` son recursos distintos, así que el plan destruye los cinco antiguos (`because aws_vpc.main is not in configuration`) y crea los del módulo. El security group y la instancia se reemplazan porque cambian de VPC y de subnet:

```
  # aws_instance.web must be replaced
      ~ subnet_id                            = "subnet-eb221aa83e0fea029" -> (known after apply) # forces replacement

  # aws_security_group.web must be replaced
      ~ vpc_id                 = "vpc-19b51dcee6c0434c6" -> (known after apply) # forces replacement

  # aws_vpc.main will be destroyed
  # (because aws_vpc.main is not in configuration)
  ...
  # module.vpc.aws_vpc.this[0] will be created
  # module.vpc.aws_internet_gateway.this[0] will be created
  # module.vpc.aws_subnet.public[0] will be created
  # module.vpc.aws_route_table.public[0] will be created
  # module.vpc.aws_route.public_internet_gateway[0] will be created
  # module.vpc.aws_route_table_association.public[0] will be created
  # module.vpc.aws_default_network_acl.this[0] will be created
  # module.vpc.aws_default_route_table.default[0] will be created
  # module.vpc.aws_default_security_group.this[0] will be created

Plan: 11 to add, 0 to change, 7 to destroy.

Changes to Outputs:
  ~ public_ip = "54.214.181.202" -> (known after apply)
```

El módulo crea alguna cosa más de lo que tenía yo: la ruta va como un recurso aparte (`aws_route`) en vez de dentro de la tabla, y además gestiona la ACL, la tabla de rutas y el security group por defecto de la VPC para dejarlos etiquetados. En un entorno real no querría tirar la red para un refactor y usaría bloques `moved {}` para decirle a Terraform que es el mismo recurso con otro nombre, pero aquí la ruta no encaja uno a uno y en LocalStack recrear no cuesta nada, así que lo dejo recrear.

```
aws_instance.web: Destroying... [id=i-99558ba3ad4217c5d]
...
aws_vpc.main: Destruction complete after 0s
module.vpc.aws_vpc.this[0]: Creation complete after 0s [id=vpc-446c7cff46a00f5b2]
module.vpc.aws_internet_gateway.this[0]: Creation complete after 0s [id=igw-cf43fbd9e5366ef05]
module.vpc.aws_route_table.public[0]: Creation complete after 1s [id=rtb-9797c7525c985de4f]
module.vpc.aws_route.public_internet_gateway[0]: Creation complete after 0s [id=r-rtb-9797c7525c985de4f1080289494]
aws_security_group.web: Creation complete after 1s [id=sg-93115bcf7d79a77b2]
module.vpc.aws_subnet.public[0]: Creation complete after 11s [id=subnet-2a16ded50cff38571]
module.vpc.aws_route_table_association.public[0]: Creation complete after 0s [id=rtbassoc-4b5a945db9d73f0d0]
aws_instance.web: Creation complete after 10s [id=i-5b5b509148e584f25]

Apply complete! Resources: 11 added, 0 changed, 7 destroyed.

Outputs:

public_ip = "54.214.46.109"
```

La infraestructura queda igual que antes, con 14 líneas de módulo en vez de cinco recursos, y la instancia nueva tiene otra IP, que el output me da sin tener que buscarla.
