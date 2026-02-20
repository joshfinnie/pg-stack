# pg-core

A self-hosted PostgreSQL server on DigitalOcean with connection pooling via PgBouncer. Infrastructure is managed with Terraform, provisioning with Ansible, and day-to-day operations with a small set of shell scripts.

## Architecture

- **DigitalOcean Droplet** — Ubuntu 22.04, provisioned via Terraform
- **PostgreSQL 16** — listening on localhost only (port 5432)
- **PgBouncer** — connection pooler exposed on port 6432 (transaction mode)
- **Firewall** — inbound SSH (22) and PgBouncer (6432) only
- **fail2ban** — brute-force protection
- **Ansible** — installs Docker, hardens the server, deploys platform files, and provisions project databases
- **Daily backups** — scheduled via cron at 3am, 30-day local retention

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html)
- A [DigitalOcean](https://www.digitalocean.com/) account with an API token and SSH key registered

## First-time setup

### 1. DigitalOcean prep

- Generate an API token at **Account > API > Tokens** (read + write scope)
- Add your SSH public key at **Settings > Security > SSH Keys**
- Note the fingerprint: `doctl compute ssh-key list`

### 2. Configure Terraform

```bash
cp infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars
```

Fill in your values:

```hcl
do_token        = "dop_v1_xxxxxxxxxxxx"
ssh_fingerprint = "aa:bb:cc:..."
ssh_public_key  = "ssh-ed25519 AAAAC3Nz... you@example.com"
```

### 3. Create the Ansible vault

The vault stores the PostgreSQL root password and any project passwords so they never appear in plaintext.

```bash
ansible-vault create ansible/group_vars/pg/vault.yml
```

Add your secrets:

```yaml
vault_pg_root_password: "a-strong-root-password"

# Add an entry here for each project you define in group_vars/pg/vars.yml
vault_project_passwords: {}
#  myapp: "a-strong-project-password"
```

### 4. Initialize Terraform

```bash
make init
```

### 5. Deploy

```bash
make deploy
```

This runs `terraform apply`, waits for SSH to become available, then runs the full Ansible playbook. You will be prompted for your vault password.

## Managing projects

Projects are declared in `ansible/group_vars/pg/vars.yml` and provisioned by Ansible — each gets its own database and user.

### Add a project

**1.** Add it to `ansible/group_vars/pg/vars.yml`:

```yaml
projects:
  - name: myapp
```

**2.** Add its password to the vault:

```bash
ansible-vault edit ansible/group_vars/pg/vault.yml
```

```yaml
vault_project_passwords:
  myapp: "a-strong-project-password"
```

**3.** Apply:

```bash
make ansible TAGS=projects
```

### Connect

```bash
psql "postgres://myapp_user:PASSWORD@DROPLET_IP:6432/myapp"
```

### Ad-hoc operations

These scripts run on the server (SSH in first with `make ssh`):

```bash
./scripts/list_projects.sh           # list all databases
./scripts/reset_password.sh myapp    # rotate a project's password
./scripts/drop_project.sh myapp      # delete a project database and user
./scripts/backup.sh                  # run a manual backup
```

## Makefile targets

| Target | Description |
|---|---|
| `make init` | `terraform init` |
| `make infra` | Apply Terraform (provision/update infrastructure) |
| `make ansible` | Run the full Ansible playbook |
| `make ansible TAGS=<tag>` | Run a subset: `security`, `docker`, `platform`, `projects` |
| `make deploy` | `infra` + wait for SSH + `ansible` — full deploy from scratch |
| `make ssh` | Open an SSH session to the droplet |
| `make destroy` | Tear down all infrastructure |

## Maintenance

```bash
# View logs
docker logs pg-core
docker logs pg-bouncer

# Restart services
cd ~/platform && docker compose restart

# Update images
cd ~/platform && docker compose pull && docker compose up -d

# Restore from backup
gunzip -c ~/scripts/backups/all-YYYY-MM-DD.sql.gz | docker exec -i pg-core psql -U postgres
```

## Project structure

```
pg-core/
├── Makefile
├── ansible/
│   ├── ansible.cfg
│   ├── pg.yaml                    # Main playbook
│   ├── templates/
│   │   └── env.j2                 # .env template (rendered from vault)
│   └── group_vars/pg/
│       ├── vars.yml               # Projects list and variable references
│       └── vault.yml              # Encrypted secrets (ansible-vault)
├── infra/terraform/
│   ├── main.tf                    # Droplet + firewall
│   ├── variables.tf
│   ├── outputs.tf
│   ├── cloud-init.yml.tpl         # User + SSH key bootstrap
│   └── terraform.tfvars.example
├── platform/
│   ├── docker-compose.yml         # PostgreSQL + PgBouncer
│   └── .env                       # Generated from vault at deploy time (git-ignored)
└── scripts/
    ├── backup.sh
    ├── create_project.sh
    ├── drop_project.sh
    ├── list_projects.sh
    └── reset_password.sh
```

## Security

- SSH key-only authentication (password auth disabled via Ansible)
- Root login disabled
- PostgreSQL bound to localhost — all external connections go through PgBouncer
- UFW enabled with default-deny; only SSH and PgBouncer allowed
- fail2ban for brute-force protection
- Secrets managed via Ansible Vault (never in plaintext in the repo)
- Docker log rotation configured (50 MB / 5 files per container)
- DigitalOcean droplet monitoring and weekly snapshots enabled

## License

MIT
