# Módulo 06 - Infraestructura como Código

Este módulo se centra en definir y desplegar infraestructura en AWS con Terraform: red, seguridad y una instancia EC2 accesible desde internet.

## 🧠 Objetivos

- Crear una VPC con acceso a internet: internet gateway, subnet pública y tabla de rutas.
- Definir security groups para HTTP y SSH.
- Desplegar una instancia EC2 free tier con key pair y acceso por SSH.
- Instalar Docker con `user_data` y servir NGINX en el puerto 80.
- Exponer datos con `output`.
- Refactorizar la red usando el módulo oficial de VPC.

## 🛠️ Tecnologías utilizadas

- **Terraform**: Definición de la infraestructura como código.
- **AWS**: VPC, EC2, security groups y key pairs.
- **Docker**: Ejecución de NGINX en la instancia.

## ✅ Pre-requisitos

- Terraform
- Cuenta de AWS y AWS CLI configurado
- Cliente SSH

## 📄 Documentación

- [Laboratorio.md](./Laboratorio.md): enunciados de los ejercicios y desarrollo/resolución paso a paso.
