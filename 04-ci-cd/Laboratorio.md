# 🔁 Laboratorio CI/CD

Para superar el módulo hay que entregar como mínimo:

- Los ejercicios de Jenkins.
- La parte obligatoria de los ejercicios de GitHub Actions.
- Uno de los dos ejercicios opcionales de la parte de GitHub Actions.

De los opcionales elijo el **Ejercicio 3** (tests e2e).

## Ejercicios Jenkins

### Ejercicio 1. CI/CD de una Java + Gradle

En el directorio raíz del código fuente (`jenkins-resources/calculator`), crear un `Jenkinsfile` que contenga una pipeline declarativa. Para ejecutar Jenkins en local con las dependencias necesarias se puede construir una imagen a partir de `jenkins-resources/gradle.Dockerfile`.

#### 📋 Requisitos

- [ ] **Checkout**. Descarga de código desde un repositorio remoto, preferentemente GitHub.
- [ ] **Compile**. Compilar el código fuente con `gradlew compileJava`.
- [ ] **Unit Tests**. Ejecutar los test unitarios con `gradlew test`.

#### 🛠️ Resolución

<!-- Pegar aquí los manifiestos/comandos usados y capturas de verificación -->

---

### Ejercicio 2. Usar la imagen Docker de Gradle como build runner

Modificar la pipeline anterior para que utilice la imagen Docker de Gradle como build runner.

#### 📋 Requisitos

- [ ] Levantar Jenkins con Docker in Docker.
- [ ] Tener instalados los plugins `Docker` y `Docker Pipeline`.
- [ ] Usar la imagen `gradle:6.6.1-jre14-openj9`.

#### 🛠️ Resolución

<!-- Pegar aquí los manifiestos/comandos usados y capturas de verificación -->

---

## Ejercicios GitHub Actions

### Ejercicio 1. Workflow CI para el proyecto de frontend - OBLIGATORIO

Copiar el directorio `.start-code/hangman-front` en el directorio raíz del mismo repositorio que se usó en las clases de GitHub Actions (o en uno nuevo). Crear un workflow que se dispare cuando haya cambios en `hangman-front` y exista una nueva pull request (las dos condiciones a la vez).

#### 📋 Requisitos

- [ ] Build del proyecto de front.
- [ ] Ejecutar los unit tests.

#### 🛠️ Resolución

<!-- Pegar aquí los manifiestos/comandos usados y capturas de verificación -->

---

### Ejercicio 2. Workflow CD para el proyecto de frontend - OBLIGATORIO

Crear un workflow que se dispare manualmente.

#### 📋 Requisitos

- [ ] Crear una nueva imagen de Docker.
- [ ] Publicar dicha imagen en el [container registry de GitHub](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

#### 🛠️ Resolución

<!-- Pegar aquí los manifiestos/comandos usados y capturas de verificación -->

---

### Ejercicio 3. Workflow que ejecute tests e2e - OPCIONAL

Crear un workflow que se lance de la manera que se elija y ejecute los tests e2e de `.start-code/hangman-e2e/e2e`. Se puede usar [Docker Compose](https://docs.docker.com/compose/gettingstarted/) o [Cypress action](https://github.com/cypress-io/github-action).

Para ejecutar los tests tienen que estar corriendo el front y la api:

```bash
docker run -d -p 3001:3000 hangman-api
docker run -d -p 8080:8080 -e API_URL=http://localhost:3001 hangman-front

cd hangman-e2e/e2e
npm run open
```

#### 📋 Requisitos

- [ ] Levantar `hangman-api` y `hangman-front` en el workflow.
- [ ] Ejecutar los tests e2e.

#### 🛠️ Resolución

<!-- Pegar aquí los manifiestos/comandos usados y capturas de verificación -->

---

### Ejercicio 4. Custom JavaScript Action - OPCIONAL

Crear una custom JavaScript Action que se ejecute cada vez que una issue tenga la etiqueta `motivate` y pinte por consola un mensaje motivacional. Referencia: [crear una JavaScript action](https://docs.github.com/es/actions/creating-actions/creating-a-javascript-action).

```bash
curl https://favqs.com/api/qotd
```

#### 📋 Requisitos

- [ ] Disparar la acción al etiquetar una issue con `motivate`.
- [ ] Obtener una frase de la API y pintarla por consola.

#### 🛠️ Resolución

<!-- Pegar aquí los manifiestos/comandos usados y capturas de verificación -->
