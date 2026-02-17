# PG Stack (DigitalOcean)

A self-hosted PostgreSQL server on DigitalOcean with connection pooling via PgBouncer. Deploy with Terraform, manage databases with simple shell scripts.

## Architecture

- **DigitalOcean Droplet** running Ubuntu 22.04 with Docker
- **PostgreSQL 16** listening on localhost only (port 5432)
- **PgBouncer** connection pooler exposed on port 6432 (transaction mode)
- **Firewall** allowing only SSH (22) and PgBouncer (6432)
- **fail2ban** for brute-force protection

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed locally
- A [DigitalOcean](https://www.digitalocean.com/) account with API access
- An SSH key added to your DigitalOcean account

## Setup

### 1. Configure Terraform

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your credentials:

```hcl
do_token        = "dop_v1_xxxxxxxxxxxx"
ssh_fingerprint = "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99"
ssh_public_key  = "ssh-ed25519 AAAAC3Nz... you@example.com"
```

You can find your SSH key fingerprint with:

```bash
doctl compute ssh-key list
```

### 2. Deploy

```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```

### 3. Copy files to the droplet

Wait a couple minutes for cloud-init to finish, then:

```bash
export DROPLET_IP=$(cd infra/terraform && terraform output -raw droplet_ip)

scp -r platform $USER@$DROPLET_IP:~/
scp -r scripts $USER@$DROPLET_IP:~/
```

### 4. Start PostgreSQL

```bash
ssh $USER@$DROPLET_IP

cd ~/platform
docker compose up -d
docker ps  # verify pg-core and pg-bouncer are running
```

## Usage

### Create a project database

```bash
cd ~/scripts
./create_project.sh myapp
```

This creates a database and user, outputs a connection string, and saves credentials to `~/scripts/secrets/projects.csv`.

### Connect

```bash
psql "postgres://myapp_user:PASSWORD@DROPLET_IP:6432/myapp"
```

### Other commands

```bash
./list_projects.sh           # list all databases
./reset_password.sh myapp    # reset a project's password
./drop_project.sh myapp      # delete a project database and user
./backup.sh                  # dump all databases (keeps 30 days)
```

### Admin access

```bash
ssh $USER@$DROPLET_IP
docker exec -it pg-core psql -U postgres
```

## Maintenance

```bash
# View logs
docker logs pg-core
docker logs pg-bouncer

# Restart services
cd ~/platform && docker compose restart

# Update PostgreSQL
cd ~/platform && docker compose pull && docker compose up -d

# Restore from backup
gunzip -c backups/all-2024-01-15.sql.gz | docker exec -i pg-core psql -U postgres
```

## Tear down

```bash
cd infra/terraform
terraform destroy
```

## Project structure

```
pg-stack/
├── infra/terraform/
│   ├── main.tf                # Droplet + firewall
│   ├── variables.tf           # Input variables
│   ├── outputs.tf             # Output values
│   ├── cloud-init.yml.tpl     # Droplet bootstrap
│   └── terraform.tfvars.example
├── platform/
│   ├── docker-compose.yml     # PostgreSQL + PgBouncer
│   └── .env                   # Root password (git-ignored)
├── scripts/
│   ├── create_project.sh
│   ├── drop_project.sh
│   ├── reset_password.sh
│   ├── list_projects.sh
│   └── backup.sh
└── .gitignore
```

## Security

- SSH key-only authentication (password auth disabled)
- PostgreSQL bound to localhost only
- All external connections go through PgBouncer
- fail2ban installed for brute-force protection
- Firewall restricts inbound to SSH + PgBouncer only
- Consider restricting firewall source IPs for production use

## License

MIT
