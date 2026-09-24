# Errores y hallazgos

## E01 — Controlador MySQL conectado a MariaDB

- **Síntoma:** al iniciar `api-facturas`, Hibernate mostró `Unknown column 'RESERVED' in 'WHERE'`. La API respondía, pero quedaba un aviso de incompatibilidad.
- **Causa:** el proyecto usaba MySQL Connector/J y la URL `jdbc:mysql://` para un servidor MariaDB 11.8.9. El controlador intentó consultar una columna `RESERVED` que no existe en `INFORMATION_SCHEMA.KEYWORDS` de MariaDB.
- **Corrección:** se sustituyó la dependencia por MariaDB Connector/J 3.5.10, se cambió la URL a `jdbc:mariadb://`, se quitó el dialecto MySQL fijado manualmente y se desactivó `spring.jpa.open-in-view`.
- **Verificación:** tras reconstruir la imagen `fintech-nova-api-facturas:1.0.1`, los logs mostraron `org.mariadb.jdbc.Connection`, no repitieron el aviso y `GET /facturas` devolvió HTTP 200 con las dos facturas iniciales.
- **Evidencia para adjuntar:** capturas de los logs antes y después, y de la respuesta HTTP.

## E02 — Límite de consultas de la API de geolocalización

- **Síntoma:** al crear una transacción con `origen_ip=8.8.8.8`, el campo `pais` quedó vacío.
- **Causa observada:** el log de `api-transacciones` mostró `La API externa de geolocalizacion devolvio un error: RateLimited`.
- **Comportamiento previsto:** la transacción se guardó igualmente; una falla del proveedor externo no impide el ABM.
- **Verificación:** el POST creó la transacción `id=3`. Luego, el PUT sobre esa transacción con `origen_ip=1.1.1.1` obtuvo `pais=Australia`, y un GET confirmó que se persistió.
- **Mejora posible:** hacer las pruebas automáticas con una respuesta simulada del proveedor externo y mostrar en la interfaz cuándo no pudo determinarse el país.