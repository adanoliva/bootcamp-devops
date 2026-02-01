# 🐳 Laboratorio Contenedores - Retos del final del módulo 🕵🏻‍♀️🫆

## 🔥 Reto 1: MongoDB en Contenedor
Objetivo: Ejecutar MongoDB dentro de un contenedor y conectar el backend (ejecutándose localmente) para que pueda recuperar, crear, modificar y eliminar clases de la base de datos.

### 📋 Requisitos:
- Crear una red Docker para la comunicación
- Ejecutar MongoDB en un contenedor con persistencia de datos
- Ejecutar el backend localmente conectándose a tu nuevo MongoDB
- Verificar que el CRUD funciona correctamente usando la extensión REST Client y el archivo backend/client.http del stack que hayas elegido
- ✨ Puedes instalar la extensión de MongoDB for VS Code o usar MongoDB Compass para verificar que los datos se almacenan correctamente

¡Perfecto! Si has llegado hasta aquí, ya tienes MongoDB corriendo en un contenedor y tu backend puede comunicarse con él. ¡Buen trabajo! 🎉

## 🐳 Reto 2: Dockerizar el Backend
Objetivo: Crear un Dockerfile para el backend y ejecutarlo en contenedor, conectado a MongoDB via red Docker.

### 📋 Requisitos:
- Crear un Dockerfile para el backend (para .NET para o Node.js)
- Construir la imagen del backend
- Ejecutar el backend en un contenedor en la red Docker que creaste en el Reto 1
- Verificar que se conecta correctamente a MongoDB
- Exponerse el puerto 5000 para que sea accesible

💡 Tips:
Define variables de entorno adecuadas para la conexión a MongoDB
Asegúrate de que la imagen sea lo más eficiente posible
Usa puertos correctos (5000 para la API)

## 🎨 Reto 3: Dockerizar el Frontend
Objetivo: Crear un Dockerfile para el frontend y ejecutarlo en contenedor, conectado al backend via red Docker.

### 📋 Requisitos:
- Crear un Dockerfile para el frontend
- Construir la imagen del frontend
- Ejecutar el frontend en un contenedor en la red Docker
- Configurar las variables de entorno para conectarse al backend en http://topics-api:5000/api/classes
- Acceder a la interfaz desde el navegador en el puerto 3000

💡 Tips:
El frontend debe ser accesible desde http://localhost:3000
Configura las variables de entorno para apuntar al backend correcto
A través de los terminales de ambos componentes, e incluso desde la propia web podrás verificar que todo funciona correctamente

## 🎪 Reto 4: Docker Compose - Todo Junto
Objetivo: Usar Docker Compose para orquestar todos los servicios (MongoDB, Backend, Frontend) como un director de orquesta.

### 📋 Requisitos:
- Crear un compose.yml que incluya los tres servicios
- Configurar la red compartida lemoncode-network
- Definir volumen para persistencia de MongoDB
- Establecer todas las variables de entorno necesarias
- Exponer los puertos correctos (3000 para frontend, 5000 para API, 27017 para MongoDB)
- Definir dependencias entre servicios
- Levantar toda la aplicación con un único comando
- Acceder a la aplicación desde el navegador en http://localhost:3000

💡 Tips:
Usa depends_on para ordenar el inicio de los servicios
Mapea el volumen para persistencia de datos
Define claramente las variables de entorno para cada servicio
Documenta los comandos útiles (up, down, logs, etc.)

## Entregables

### 📦 Reto 1: MongoDB en Contenedor
- Comandos utilizados para crear la red Docker
- Comando para ejecutar el contenedor de MongoDB
- Configuración de conexión del backend a MongoDB
- Prueba REST Client mostrando peticiones exitosas (backend/client.http)

### 🐳 Reto 2: Dockerizar el Backend
- Archivo Dockerfile del backend
- Comando para construir la imagen
- Comando para ejecutar el contenedor del backend
- Prueba REST Client validando que la API responde correctamente

### 🎨 Reto 3: Dockerizar el Frontend
- Archivo Dockerfile del frontend
- Comando para construir la imagen del frontend
- Comando para ejecutar el contenedor del frontend
- Archivo .env o variables de entorno configuradas correctamente

### 🎪 Reto 4: Docker Compose
- Archivo compose.yml completo y documentado con comentarios
- Archivo .env (si es necesario) con variables de entorno
- Comando docker-compose up ejecutándose exitosamente
- Captura de pantalla de todos los servicios corriendo (docker-compose ps)
- Captura de pantalla de la aplicación completa en http://localhost:3000