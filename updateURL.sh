#!/bin/bash

# Function to fetch connector configuration
fetch_connector_config() {
    local connector_name="$1"
    local connect_url="$2"
    curl -s "${connect_url}/connectors/${connector_name}/config"
}

# Function to read JDBC URL from properties file
read_jdbc_url_from_properties() {
    local file_path="$1"
    local jdbc_url
    jdbc_url=$(grep '^URL=' "$file_path" | cut -d'=' -f2)
    echo "$jdbc_url"
}

# Function to update connector configuration with new JDBC URL
update_connector_config() {
    local connector_config="$1"
    local jdbc_url="$2"
    echo "$connector_config" | jq ".config.\"connection.url\" = \"$jdbc_url\""
}

# Function to update connector configuration via REST API
update_connector_config_via_rest() {
    local connector_name="$1"
    local connector_config="$2"
    local connect_url="$3"
    curl -s -X PUT -H "Content-Type: application/json" -d "$connector_config" "${connect_url}/connectors/${connector_name}/config" >/dev/null
}

# Main function
main() {
    connect_url="http://kfk-conn-svc:8083"  # Kafka Connect REST API URL
    connector_names_file="/path/to/connector_names.txt"  # Path to file containing list of connector names
    properties_file_path="/secret/kafka_con_db.properties"  # Path to properties file

    # Read list of connector names from file
    while IFS= read -r connector_name; do
        echo "Processing connector: $connector_name"

        # Fetch connector configuration
        connector_config=$(fetch_connector_config "$connector_name" "$connect_url")
        if [ -z "$connector_config" ]; then
            echo "Error fetching connector configuration for $connector_name"
            continue
        fi

        # Read JDBC URL from properties file
        jdbc_url=$(read_jdbc_url_from_properties "$properties_file_path")
        if [ -z "$jdbc_url" ]; then
            echo "Skipping connector $connector_name due to missing JDBC URL from properties file."
            continue
        fi

        # Update connector configuration with new JDBC URL
        updated_connector_config=$(update_connector_config "$connector_config" "$jdbc_url")

        # Update connector configuration via REST API
        update_connector_config_via_rest "$connector_name" "$updated_connector_config" "$connect_url"
        echo "Connector configuration updated successfully for $connector_name"
    done < "$connector_names_file"
}

# Run main function
main
