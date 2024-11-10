# Ambar Emulator

![Main Branch - Build Status](https://github.com/ambarltd/emulator-docker/actions/workflows/test.yaml/badge.svg?branch=main)

This is a Dockerized emulator of [Ambar](https://ambar.cloud) for testing and development purposes.

Ambar replaces infrastructure such as Kafka, Debezium, Kafka Connect, RabbitMQ, and others. Ambar allows you to 
read messages from one or more database tables, and forward each new row as a message to one or more HTTP endpoints. 
Messages are sent in parallel (according to a partitioning column), with ordering guarantees (per partition key), 
and with delivery guarantees (at least once).

- The Docker image is available [on DockerHub](https://hub.docker.com/r/ambarltd/emulator)
- The source code is available [on GitHub](https://github.com/ambarltd/emulator)

---

## Usage

### Setup

Create a configuration file, and mount it into the emulator's container at `/opt/emulator/config/config.yaml`.

For example, if you are using `docker compose`:

```yaml
services:
  ambar-emulator:
    image: ambarltd/emulator:latest
    container_name: ambar-emulator
    restart: always
    volumes:
      # copy the configuration file in your host to the emulator 
      - ./path/to/config.yaml:/opt/emulator/config/config.yaml
      # pick a directory in your host to persist the emulator state
      - ./path/to/volume/ambar-emulator:/root/.local/share/ambar-emulator
  web-server:
    image: your-web-server-image
    container_name: web-server
    restart: always
    environment:
      EVENT_STORE_HOST: "172.30.0.102"
      EVENT_STORE_PORT: 5432
      EVENT_STORE_DATABASE_NAME: "my_database"
      EVENT_STORE_USER: "my_username"
      EVENT_STORE_PASSWORD: "my_password"
      EVENT_STORE_CREATE_TABLE_WITH_NAME: "event_table" # something needs to create the table, we're assuming the webserver is doing that
    expose:
      - 8080
    networks:
      development-network:
        ipv4_address: 172.43.0.102
  postgres-events:
    image: postgres:16.4
    container_name: postgres-events
    restart: always
    volumes:
      - ./data/postgres-events/pg-data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: my_username
      POSTGRES_DB: my_database
      POSTGRES_PASSWORD: my_password
    expose:
      - 5432
    networks:
      development-network:
        ipv4_address: 172.43.0.103

networks:
    development-network:
        driver: bridge
        ipam:
            config:
                - subnet: 172.43.0.0/24
```

### Configuration

Example `configuration.yaml`:

```yaml
# Connections to your databases.
# The Emulator will read data from those databases.
data_sources:
  - id: postgres_source
    description: Events Table in Postgres
    type: postgres
    host: 172.43.0.103
    port: 5432
    username: my_username
    password: my_password
    database: my_database
    table: events_table
    columns:
      - serial_column
      - event_id
      - event_name
      - aggregate_id
      - aggregate_version
      - json_payload
      - json_metadata
      - recorded_on
      - causation_id
      - correlation_id
    serialColumn: serial_column
    partitioningColumn: correlation_id

# Connections to your endpoint.
# The Emulator will send data it reads from the databases to these endpoints.
data_destinations:

  # Send data via HTTP
  - id: http_destination
    description: Projection 1
    type: http-push
    endpoint: http://172.30.0.102:8080/projections/projection-1
    username: username-123
    password: password-123
    sources:
      - postgres_source
```

### Further Work:

- [ ] Add support for MySQL
- [ ] Add support for MariaDB
- [ ] Add support for SQL Server
- [ ] Add support for Oracle
- [ ] Add support for MongoDB
- [ ] Add support for filtering capabilities
