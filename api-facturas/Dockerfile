# ETAPA 1: El Taller de Construcción (Pesado)
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app

# Truco de Caché: Copiamos solo el índice de librerías primero
COPY pom.xml .
RUN mvn dependency:go-offline

# Ahora sí, copiamos tu código Java y lo compilamos
COPY src ./src
RUN mvn clean package -DskipTests

# ETAPA 2: El Living Limpio (Liviano)
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# El camión de mudanza: traemos el .jar terminado
COPY --from=builder /app/target/*.jar app.jar

# Documentamos el puerto (el enunciado pide el 8080)
EXPOSE 8080

# Creamos un grupo y un usuario raso sin privilegios (Estándar de seguridad OWASP)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
# Le ordenamos a Docker que deje de ser administrador y use este usuario inofensivo
USER appuser

# El botón de encendido irrompible
ENTRYPOINT ["java", "-jar", "app.jar"]    