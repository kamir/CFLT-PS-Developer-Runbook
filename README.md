# Confluent Java Toolkit

Java developer toolkit for building, testing, and operating applications on **Confluent Cloud** with PCI-DSS compliance.

## What's Inside

| Module | Description |
|---|---|
| `producer-consumer-app` | Payment event producer and consumer with masked card data |
| `kstreams-app` | Real-time fraud detection using Kafka Streams |

## Quick Start

```bash
# 1. Start local Kafka
cd docker && docker-compose up -d broker schema-registry && cd ..

# 2. Create topics
./scripts/create-topics.sh local

# 3. Build
mvn clean package -DskipTests

# 4. Run producer
java -Dapp.env=dev -jar producer-consumer-app/target/producer-consumer-app-1.0.0-SNAPSHOT.jar produce

# 5. Run KStreams fraud detection (another terminal)
java -Dapp.env=dev -jar kstreams-app/target/kstreams-app-1.0.0-SNAPSHOT.jar

# 6. Run tests
mvn test
```

## Documentation

See **[RUNBOOK.md](RUNBOOK.md)** for the complete Developer Runbook covering:

- Application lifecycle (DEV → QA → PROD)
- Git-Flow branching model
- GitOps deployment model
- Configuration management across environments
- PCI-DSS compliance controls
- Developer toolbox (CLI tools, kcat, Schema Registry, K8s)
- Troubleshooting & diagnostics guide

## License

Apache License 2.0 — see [LICENSE](LICENSE).
