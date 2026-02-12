# Confluent Java Toolkit
![License](https://img.shields.io/badge/License-Apache%202.0-blue)
![Java](https://img.shields.io/badge/Java-17-orange)
![Go](https://img.shields.io/badge/Go-1.22-00ADD8)

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

# 4. (Optional) Generate client.properties from .env
./scripts/create-client-properties.sh -local

# 5. Run producer (demo)
make demo-produce

# 6. Run KStreams processor (another terminal)
make demo-process

# 7. Run consumer (another terminal)
make demo-consume
```

## Scripts

See **[scripts/README.md](scripts/README.md)** for documentation of all automation scripts (infrastructure setup, diagnostics, workshop validation, coach tools, QA checklist generation).

## Documentation

See **[RUNBOOK.md](RUNBOOK.md)** for the complete Developer Runbook covering:

- Application lifecycle (DEV → QA → PROD)
- Git-Flow branching model
- GitOps deployment model
- Configuration management across environments
- PCI-DSS compliance controls
- Developer toolbox (CLI tools, kcat, Schema Registry, K8s)
- Troubleshooting & diagnostics guide

Additional docs:
- **[Course Structure](docs/COURSE_STRUCTURE.md)**
- **[Tools Warmup](docs/TOOLS_WARMUP.md)**
- **[Students 1st Actions](procedures/STUDENTS_1ST_ACTIONS.md)**

## License

Apache License 2.0 — see [LICENSE](LICENSE).
