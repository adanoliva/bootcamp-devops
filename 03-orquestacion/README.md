# Módulo 03 - Orquestación

Este módulo se centra en la orquestación de aplicaciones contenerizadas con Kubernetes, partiendo de un monolito con persistencia en memoria, pasando por el mismo monolito con base de datos, hasta separar UI y API detrás de un Ingress.

## 🧠 Objetivos

- Construir imágenes Docker de una aplicación completa (UI + API).
- Pasar de persistencia en memoria a persistencia real con base de datos (StatefulSet + PersistentVolume).
- Separar una aplicación monolítica en servicios independientes (UI y API).
- Desplegar Deployments y Services en Kubernetes.
- Configurar un Ingress para exponer varios servicios del clúster.

## 🛠️ Tecnologías utilizadas

- **Docker**: Construcción y ejecución de imágenes.
- **Kubernetes / Minikube**: Orquestación de contenedores (Deployment, StatefulSet, Service, ConfigMap, Ingress).
- **Node.js 22.***: Runtime de la API.
- **PostgreSQL**: Base de datos para persistencia.
- **Nginx**: Ingress controller / servidor de la UI.

## ✅ Pre-requisitos

- Docker
- Minikube
- kubectl

## 📄 Documentación

- [Laboratorio.md](./Laboratorio.md): enunciados de los ejercicios y desarrollo/resolución paso a paso.
