# Odoo / OCB server with Docker Compose

This repository provides a production-ready stack for running Odoo or OCB with PostgreSQL, using Docker Compose. It supports external addons, configurable runtime settings, and secure defaults.

## Features

- Odoo versions 16-19
- Source from OCA/OCB or Odoo SA repository
- PostgreSQL as the database backend
- Configurable via environment variables
- External addons support
- Secure admin password generation
- Persistent data and configuration
- Health checks for database
- Resource limits for Odoo workers


## Quick Start

1. Clone this repository or copy the files into your project directory.
2. Edit `.env` file (if needed) to set your preferred Odoo and database credentials[^1_3].
3. Build and start the stack:

```bash
docker compose up -d
```


## Configuration

### Environment Variables

- `.env` file
    - `ODOO_REPO`: Odoo source repository (OCA/OCB or official Odoo)
    - `ODOO_BRANCH`: Odoo version/branch (default: `17.0`)
    - `ODOO_UID`, `ODOO_USER`: User and UID for Odoo process
    - `ODOO_BASE_DIR`, `ODOO_SRC_DIR`, `ODOO_DATA_DIR`: Paths for Odoo data and source
    - `ODOO_DB_USER`, `ODOO_DB_PASSWORD`: Database credentials[^1_3]


### Docker Compose

- `compose.yml`
    - Defines Odoo and PostgreSQL services
    - Exposes ports `8171` (XML-RPC) and `8172` (gevent/longpolling)
    - Mounts volumes for addons, data, and configuration
    - Sets resource limits and security defaults[^1_1]


### Entrypoint

- `entrypoint.sh`
    - Sets up Odoo configuration from environment variables
    - Generates a random admin password if not set
    - Creates required directories and sets permissions
    - Initializes the database if not already done
    - Runs Odoo as the specified user[^1_4]


### Dockerfile

- `Dockerfile`
    - Builds a Debian-based image with Python 3.12
    - Installs system dependencies and wkhtmltopdf
    - Creates the Odoo user and clones the source code
    - Installs Python dependencies
    - Sets up the entrypoint[^1_2]


## Customization

- Addons: Place your custom addons in `./addons` directory.
- Configuration: Edit `compose.yml` or `.env` to change Odoo or database settings.
- Resources: Adjust memory and CPU limits in `compose.yml` as needed.


## Volumes

- `./addons`: External Odoo addons
- `./data`: Odoo file store and sessions
- `./conf`: Odoo configuration files
- `./data/postgres`: PostgreSQL data directory


## Security

- Admin password: Generated automatically if not set
- Database password: Must be set in `.env`
- Resource limits: Prevents excessive resource usage


## Ports

| Service | Port | Description |
| :-- | :-- | :-- |
| Odoo | 8171 | XML-RPC interface |
| Odoo | 8172 | Gevent/longpolling |

## Database

- PostgreSQL: Managed as a separate container
- Health check: Ensures database is ready before Odoo starts[^1_1]


## Notes

- First run: The database and admin password will be initialized automatically.
- Restart: The stack can be restarted without losing data.
- Logging: Odoo logs to stdout by default.

---

This setup is suitable for development, testing, and small production environments. Adjust resource limits and security settings for larger deployments.
