# Aquí se crea la imagen base para el entorno de producción.
# El entorno de producción requiere de 2 pasos, uno para hacer un build del proyecto de keycloak
# y otro para hacer el despliegue, en la documentación oficial hay un ejemplo de esto
# https://www.keycloak.org/server/containers

################################

# INICIO PRIMERA PARTE

################################

# Creamos la imagen base que vamos a buildear

FROM quay.io/keycloak/keycloak:25.0 as builder

# Activar health y metricas de ayuda
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Directorio de trabajo de la imagen
WORKDIR /opt/keycloak

# Copia de archivos de configuración de los temas de Houndoc
# Para que este dockerFile funcione al actualizarse el tema, debe hacerse
# en la dirección que cada quien tenga de keycloak_home
COPY /themes/ /opt/keycloak/themes
COPY /providers/ /opt/keycloak/providers

COPY keycloak.conf /opt/keycloak/conf/keycloak.conf

# Ejecutamos el build

ARG db_vendor

RUN /opt/keycloak/bin/kc.sh build --db=$db_vendor

## ---------------------------------------------------------------- ##
# FIN PRIMERA PARTE
## ---------------------------------------------------------------- ##

################################

# INICIO SEGUNDA PARTE

################################

FROM quay.io/keycloak/keycloak:25.0

# Variables de entorno del sistema
ENV KC_HOSTNAME_STRICT=false
ENV KC_HTTP_ENABLED=false
ENV KC_HOSTNAME_STRICT_BACKCHANNEL=true
ENV KC_HTTPS_PORT=8443
ENV KC_HTTP_PORT=8180
ENV KC_PROXY=edge
ENV PROXY_ADDRESS_FORWARDING=true

# Tomamos el programa recién construido en la imagen anterior y lo copiamos 
# en la actual carpeta de trabajo (donde se sobreescribe)

COPY --from=builder /opt/keycloak/ /opt/keycloak/

COPY /truststores/ /opt/keycloak/truststores

ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "--config-file=/opt/keycloak/conf/keycloak.conf", "start", "--optimized"]

## ---------------------------------------------------------------- ##
# FIN SEGUNDA PARTE
## ---------------------------------------------------------------- ##