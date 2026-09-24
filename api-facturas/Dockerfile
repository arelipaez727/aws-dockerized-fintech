FROM maven:3.9.16-eclipse-temurin-21-noble AS build

WORKDIR /build

COPY api-facturas/pom.xml ./
RUN mvn -B -ntp dependency:go-offline

COPY api-facturas/src/ ./src/
RUN mvn -B -ntp package

FROM eclipse-temurin:21-jre-noble

WORKDIR /app

RUN groupadd --system --gid 10001 app \
    && useradd --system --uid 10001 --gid app --no-create-home app

COPY --from=build --chown=app:app /build/target/api-facturas.jar ./api-facturas.jar

USER app

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/api-facturas.jar"]