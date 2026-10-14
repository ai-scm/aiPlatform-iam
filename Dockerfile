# Aquí se crea la imagen base para el entorno de producción.
# El entorno de producción requiere de 2 pasos, uno para hacer un build del proyecto de keycloak
# y otro para hacer el despliegue, en la documentación oficial hay un ejemplo de esto
# https://www.keycloak.org/server/containers

################################

# INICIO PRIMERA PARTE

################################

# Creamos la imagen base que vamos a buildear

ARG KEYCLOAK_VERSION=26.7.2
ARG AWS_CLI_IMAGE=public.ecr.aws/aws-cli/aws-cli:2
ARG JQ_IMAGE=ghcr.io/jqlang/jq:1.8.2

FROM ${AWS_CLI_IMAGE} AS aws-cli
FROM ${JQ_IMAGE} AS jq

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} as builder

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

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}

# Variables de entorno del sistema
ENV KC_HOSTNAME_STRICT=false
ENV KC_HTTP_ENABLED=true
ENV KC_HOSTNAME_BACKCHANNEL_DYNAMIC=false
ENV KC_HTTP_PORT=8180
ENV KC_PROXY_HEADERS=xforwarded

# Tomamos el programa recién construido en la imagen anterior y lo copiamos 
# en la actual carpeta de trabajo (donde se sobreescribe)

COPY --from=builder /opt/keycloak/ /opt/keycloak/

# El contenedor base de Keycloak no incluye un gestor de paquetes. Copiamos AWS CLI
# para resolver, durante el arranque, los valores de Secrets Manager configurados
# mediante DB_URL y DB_PASSWORD.
COPY --from=aws-cli /usr/local/aws-cli /usr/local/aws-cli
COPY --from=aws-cli /usr/local/bin/aws /usr/local/bin/aws
COPY --from=jq /jq /usr/local/bin/jq
COPY --chmod=755 docker-entrypoint.sh /opt/keycloak/bin/docker-entrypoint.sh

COPY /truststores/ /opt/keycloak/truststores

ENTRYPOINT ["/opt/keycloak/bin/docker-entrypoint.sh"]

## ---------------------------------------------------------------- ##
# FIN SEGUNDA PARTE
## ---------------------------------------------------------------- ##
