#!/bin/bash

CATALOG_DIR="/etc/trino/catalog"

# Função para criar catalog dinamicamente
create_catalog() {
    local catalog_name=$1
    local connector_type=$2
    local file="${CATALOG_DIR}/${catalog_name}.properties"
    
    echo "connector.name=${connector_type}" > "$file"
}

# Função para adicionar propriedade opcional
add_property() {
    local file=$1
    local property=$2
    local value=$3
    
    if [ ! -z "$value" ]; then
        echo "${property}=${value}" >> "$file"
    fi
}

# MySQL Catalog
if [ ! -z "$MYSQL_HOST" ]; then
    echo "Configurando MySQL catalog..."
    MYSQL_FILE="${CATALOG_DIR}/mysql.properties"
    
    create_catalog "mysql" "mysql"
    add_property "$MYSQL_FILE" "connection-url" "jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT:-3306}/${MYSQL_DATABASE:-}"
    add_property "$MYSQL_FILE" "connection-user" "$MYSQL_USER"
    if [ ! -z "$MYSQL_PASSWORD" ]; then
        add_property "$MYSQL_FILE" "connection-password" "$MYSQL_PASSWORD"
    fi
    add_property "$MYSQL_FILE" "connection-pool.max-size" "$MYSQL_MAX_CONNECTIONS"
fi

# MongoDB Catalog
if [ ! -z "$MONGODB_HOST" ]; then
    echo "Configurando MongoDB catalog..."
    MONGO_FILE="${CATALOG_DIR}/mongodb.properties"
    
    create_catalog "mongodb" "mongodb"
    
    # Monta connection string com ou sem autenticação
    if [ ! -z "$MONGODB_USER" ] && [ ! -z "$MONGODB_PASSWORD" ]; then
        MONGO_URL="mongodb://${MONGODB_USER}:${MONGODB_PASSWORD}@${MONGODB_HOST}:${MONGODB_PORT:-27017}"
    else
        MONGO_URL="mongodb://${MONGODB_HOST}:${MONGODB_PORT:-27017}"
    fi
    
    add_property "$MONGO_FILE" "mongodb.connection-url" "$MONGO_URL"
    add_property "$MONGO_FILE" "mongodb.schema-collection" "${MONGODB_SCHEMA_COLLECTION:-trino-schemas}"
fi

echo "Catalogs configurados com sucesso!"
ls -la $CATALOG_DIR

# Inicia o Trino
exec /usr/lib/trino/bin/run-trino