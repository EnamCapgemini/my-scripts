import requests
import json

def fetch_connector_config(connector_name, connect_url):
    try:
        response = requests.get(f"{connect_url}/connectors/{connector_name}/config")
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error fetching connector configuration for {connector_name}: {e}")
        return None

def read_jdbc_url_from_properties(file_path):
    jdbc_url = None
    try:
        with open(file_path, 'r') as file:
            properties = file.readlines()
            for prop in properties:
                key, value = prop.strip().split('=')
                if key.strip() == 'URL':
                    jdbc_url = value.strip()
                    break
    except Exception as e:
        print(f"Error reading JDBC URL from properties file: {e}")
    return jdbc_url

def update_connector_config(connector_config, jdbc_url):
    if 'connection.url' in connector_config['config']:
        connector_config['config']['connection.url'] = jdbc_url
    else:
        print("No 'connection.url' property found in connector configuration.")
    return connector_config

def update_connector_config_via_rest(connector_name, connector_config, connect_url):
    try:
        response = requests.put(f"{connect_url}/connectors/{connector_name}/config", 
                                headers={"Content-Type": "application/json"},
                                data=json.dumps(connector_config))
        response.raise_for_status()
        print(f"Connector configuration updated successfully for {connector_name}.")
    except Exception as e:
        print(f"Error updating connector configuration for {connector_name}: {e}")

def main():
    connect_url = "http://kfk-conn-svc:8083"  # Kafka Connect REST API URL
    connector_names_file = "/path/to/connector_names.txt"  # Path to file containing list of connector names
    properties_file_path = "/secret/kafka_con_db.properties"  # Path to properties file

    # Step 1: Read list of connector names from file
    with open(connector_names_file, 'r') as file:
        connector_names = file.readlines()
        connector_names = [name.strip() for name in connector_names]

    # Step 2: Process each connector entry
    for connector_name in connector_names:
        print(f"Processing connector: {connector_name}")

        # Step 3: Fetch connector configuration
        connector_config = fetch_connector_config(connector_name, connect_url)
        if not connector_config:
            continue

        # Step 4: Read JDBC URL from properties file
        jdbc_url = read_jdbc_url_from_properties(properties_file_path)
        if not jdbc_url:
            print("Skipping connector due to missing JDBC URL from properties file.")
            continue

        # Step 5: Update connector configuration with the new JDBC URL
        updated_connector_config = update_connector_config(connector_config, jdbc_url)

        # Step 6: Update connector configuration via REST API
        update_connector_config_via_rest(connector_name, updated_connector_config, connect_url)

if __name__ == "__main__":
    main()
