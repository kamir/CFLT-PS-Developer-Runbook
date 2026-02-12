# Scripts

Automation scripts for infrastructure setup, diagnostics, workshop validation, and QA.

## Infrastructure & Configuration

| Script | Description | Usage |
|--------|-------------|-------|
| `ccloud-setup.sh` | Bootstrap a Confluent Cloud environment (env, cluster, service account, API keys, ACLs, topics) and persist credentials to `.env`. Requires `confluent` CLI and `jq`. | `./scripts/ccloud-setup.sh <env-name>` |
| `ccloud-cleanup.sh` | Tear down a Confluent Cloud environment and all its resources. Prompts for confirmation before deletion. | `./scripts/ccloud-cleanup.sh <env-name>` |
| `create-client-properties.sh` | Generate a Kafka `client.properties` file from `.env` credentials. With `-local`, generates a `local.client.properties` for a local broker (PLAINTEXT, no SASL). | `./scripts/create-client-properties.sh` or `./scripts/create-client-properties.sh -local` |
| `create-topics.sh` | Create the payment pipeline topics (`payments`, `fraud-alerts`, `approved-payments`) on a local Docker broker or Confluent Cloud. | `./scripts/create-topics.sh local` or `./scripts/create-topics.sh cloud` |

## Diagnostics & Tooling

| Script | Description | Usage |
|--------|-------------|-------|
| `diagnose.sh` | Kafka diagnostics toolkit with checks for broker connectivity, consumer lag, topic metadata, KStreams state, Schema Registry health, and K8s pod status. Supports `-local` to skip `.env` and use local defaults. | `./scripts/diagnose.sh full` or `./scripts/diagnose.sh connectivity` |
| `kshark-init.sh` | Download and install the [kshark](https://github.com/scalytics/kshark-core) binary into `./tools`. Auto-generates `client.properties` if `.env` is present. | `./scripts/kshark-init.sh` or `KSHARK_VERSION=0.25.4 ./scripts/kshark-init.sh` |
| `kshark-scan.sh` | Run kshark topic analysis against the cluster. Performs ACL preflight checks, optional producer tests, and writes reports to `tools/kshark-reports/`. | `./scripts/kshark-scan.sh` or `KSHARK_TIMEOUT=120s ./scripts/kshark-scan.sh` |
| `kshark-diag-ccloud.sh` | Diagnose Confluent Cloud resources for kshark: prints environment, cluster, Schema Registry, API key ownership, ACLs, and topic details. | `./scripts/kshark-diag-ccloud.sh` |

## Workshop Validation

| Script | Description | Usage |
|--------|-------------|-------|
| `workshop-check.sh` | Validate workshop block completion and award badges (Bronze through Diamond, plus Master). Each block checks specific prerequisites (containers, topics, JARs, tests, Dockerfiles, K8s manifests, etc.). | `./scripts/workshop-check.sh block1` or `./scripts/workshop-check.sh final` |

## Coach Tools

Scripts for workshop coaches to monitor student progress and manage PRs.

| Script | Description | Usage |
|--------|-------------|-------|
| `bulk-pr-check.sh` | Interactive bulk PR review helper. Iterates over open workshop PRs, checks out each branch, runs validation, and offers approve/request-changes/comment actions. Requires `gh` CLI. | `./scripts/bulk-pr-check.sh` |
| `coach-check-all-students.sh` | Generate a student activity report showing commit counts and last activity for all `student/*` branches. | `./scripts/coach-check-all-students.sh` |
| `generate-workshop-report.sh` | Generate a comprehensive Markdown workshop summary report with student statistics, badge completion, and PR status. | `./scripts/generate-workshop-report.sh > report.md` |
| `verify-all-trackers.sh` | Verify that each student has created their progress tracker file on their branch. | `./scripts/verify-all-trackers.sh` |

## QA Checklist Generation

| Script | Description | Usage |
|--------|-------------|-------|
| `generate-qa-checklist.py` | Generate a styled QA Checklist spreadsheet (German) covering all 19 blocks across 4 levels. Outputs `docs/workshop/QA-Checklist.xlsx`. Requires `openpyxl`. | `python3 scripts/generate-qa-checklist.py` |
| `generate-qa-checklist-en.py` | Same as above but in English. Outputs `docs/workshop/QA-Checklist-EN.xlsx`. | `python3 scripts/generate-qa-checklist-en.py` |

## Makefile Integration

Most scripts are also available as Make targets:

```bash
make client-properties         # Generate client.properties from .env
make local-client-properties   # Generate local.client.properties
make topics                    # Create topics on local broker
make diagnose                  # Run full diagnostics
make kshark-init               # Install kshark
make kshark-scan               # Run kshark scan
make kshark-diag-ccloud        # Diagnose Confluent Cloud for kshark
make demo-produce              # Run demo producer (Confluent Cloud)
make demo-produce LOCAL=1      # Run demo producer (local Kafka)
make demo-consume LOCAL=1      # Run demo consumer (local Kafka)
make demo-process LOCAL=1      # Run demo KStreams processor (local Kafka)
```

Run `make help` for the full list of targets.
