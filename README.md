# Ambar Emulator

![Main Branch - Build Status](https://github.com/ambarltd/emulator-docker/actions/workflows/test.yaml/badge.svg?branch=main)

This is a Dockerized emulator of [Ambar](https://ambar.cloud) for testing and development environments. 

Ambar replaces infrastructure such as Kafka, Debezium, Kafka Connect, RabbitMQ, and others. Ambar allows you to 
read messages from one or more database tables, and forward each new row as a message to one or more HTTP endpoints. 
Messages are sent in parallel (according to a partitioning column), with ordering guarantees (per partition key), 
and with delivery guarantees (at least once).

- The Docker image is available [on DockerHub](https://hub.docker.com/r/ambarltd/emulator)
- The source code is available [on GitHub](https://github.com/ambarltd/emulator)

Please use the emulator in testing and development environments, ([not production environments](#limitations)).

---

## Usage

### Setup

Create a configuration file and mount it to the emulator container.

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

  mysql-events:
      image: mysql:8.0.40
      container_name: mysql-events
      restart: always
      volumes:
          - ./data/mysql-event-store:/var/lib/mysql
      environment:
          MYSQL_DATABASE: my_database
          MYSQL_ROOT_PASSWORD: my_password
      expose:
          - 3306
    networks:
      development-network:
        ipv4_address: 172.43.0.104

  backend-server:
    image: your-backend-server-image
    container_name: backend-server
    restart: always
    expose:
      - 8080
    networks:
      development-network:
        ipv4_address: 172.43.0.199

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
# The Emulator will read data from these databases.
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

  - id: mysql_source
    description: Events Table in MySQL
    type: mysql
    host: 172.43.0.104
    port: 3306
    username: root
    password: my_password
    database: my_database
    table: events_table
    columns:
      - id
      - event_id
      - event_name
      - aggregate_id
      - aggregate_version
      - json_payload
      - json_metadata
      - recorded_on
      - causation_id
      - correlation_id
    autoIncrementingColumn: id
    partitioningColumn: correlation_id

# Connections to your endpoints.
# The Emulator will send data it reads from the databases to these endpoints.
data_destinations:

  - id: projection_1
    description: Projection 1
    type: http-push
    endpoint: http://172.30.0.199:8080/projections/projection-1
    username: http-username-123
    password: http-password-123
    sources:
      - postgres_source

  - id: projection_2
    description: Projection 2
    type: http-push
    endpoint: http://172.30.0.199:8080/projections/projection-2
    username: http-username-123
    password: http-password-123
    sources:
      - mysql-source
```

### Payloads

Data destination endpoints will then receive payloads, in parallel (per partitioning column), in order (per partitioning column), and at least once. For example:

```
{
  "data_source_id": "postgres_source",
  "data_source_description": "Events Table in Postgres",
  "data_destination_id": "projection_1",
  "data_destination_description": "Projection 1",
  "payload": {
    "serial_column": 12345,
    "event_id": "e7b3a07c-4a90-4fc3-8243-7c90a33a6f4e",
    "event_name": "UserSignedUp",
    "aggregate_id": "420ac19b-1cd3-4c9c-b8d4-56bdd936ca38",
    "aggregate_version": 1,
    "json_payload": "{\"name\": \"John Doe\",\"email\": \"john.doe@example.com\"}",
    "json_metadata": "{\"ip_address\": \"192.168.1.1\",\"user_agent\": \"Mozilla/5.0\"}",
    "recorded_on": "2024-12-03T12:00:00Z",
    "causation_id": "e7b3a07c-4a90-4fc3-8243-7c90a33a6f4e",
    "correlation_id": "e7b3a07c-4a90-4fc3-8243-7c90a33a6f4e"
  }
}
```

The Emulator will move on to the next message if the endpoint replies with an acknowledgement payload, `{"result":{"success":{}}}`.

---

## Limitations

1) The emulator works well in development and test environments, but does not have the strict delivery and durability guarantees that the real Ambar [gives you](https://ambar.cloud/blog/provably-correct-data-streaming-our-white-paper) in production environments.
2) The emulator consumes more resources on your databases and web servers compared to the real Ambar. Why? Because the emulator does not implement features such as change data capture and [adaptive load](https://ambar.cloud/blog/optimal-consumption-with-adaptive-load).
3) The emulator can handle thousands of messages per second but does not scale horizontally, because the emulator can only run in a single machine.
4) The emulator doesn't provide filtering (yet - we will eventually add this).

---

## Upcoming Features:

- [ ] Add support for SQL Server
- [ ] Add support for filtering
- [ ] Add support for Oracle
- [ ] Add support for MongoDB
- [ ] Add support for DynamoDB
