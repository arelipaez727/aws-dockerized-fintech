package ar.edu.utn.frc.devops.facturas;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ApiFacturasApplication {
    private static final String[] REQUIRED_DATABASE_ENV = {
            "DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD"
    };

    public static void main(String[] args) {
        validateDatabaseEnvironment();
        SpringApplication.run(ApiFacturasApplication.class, args);
    }

    private static void validateDatabaseEnvironment() {
        for (String name : REQUIRED_DATABASE_ENV) {
            String value = System.getenv(name);
            if (value == null || value.isBlank()) {
                throw new IllegalStateException("Falta la variable de entorno obligatoria " + name);
            }
        }
    }
}
