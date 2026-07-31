
# OCI Pterodactyl Deployment

This project automates the deployment of a complete Pterodactyl Panel and Wings setup on Oracle Cloud Infrastructure (OCI) using Terraform for infrastructure provisioning and Ansible for application deployment. Additionally, it includes a Minecraft server proxy (MCRouter) for managing multiple Minecraft game servers.

## Architecture

The deployment creates:
- **OCI VM.Standard.A1.Flex instance** (2 OCPUs, 12GB RAM, 100GB storage) running Ubuntu 24.04 (Free Tier eligible)
- **Pterodactyl Panel** - Web-based game server management interface in Docker
- **Pterodactyl Wings** - Game server daemon
- **MySQL Database** - Panel data storage in Docker
- **Redis** - Caching and session storage in Docker
- **MCRouter** - Minecraft server proxy for multiple game servers in Docker
- **Caddy** - Reverse proxy and automatic SSL certificate management via Cloudflare DNS in Docker

## Prerequisites

1. **OCI Account** with appropriate permissions
2. **Terraform** installed locally
3. **Ansible** installed locally
4. **SSH Key Pair** for server access
5. **Domain name** with Cloudflare DNS management
6. **Cloudflare API Token** for SSL certificate generation with Zone.Zone Read and Zone.DNS Edit permissions

## Quick Start

### 0. Prepare the server

Ensure you have Docker, non-root user with sudo privileges, SSH access and firewall set up on your OCI instance.

You can use [ansible-initial-server-setup](https://github.com/k-wlosek/ansible-initial-server-setup) to automate this process.

### 1. Infrastructure Deployment

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your OCI credentials and preferences
terraform init
terraform plan # Review the plan output
terraform apply
```

### 2. Application Deployment

```bash
cd ../ansible/
cp group_vars/all.yml.example group_vars/all.yml

# Edit the file and optionally encrypt sensitive variables
ansible-vault encrypt group_vars/all.yml

ansible-galaxy collection install community.general
ansible-galaxy collection install community.docker

cp inventory/hosts.yml.example inventory/hosts.yml
# Edit inventory/hosts.yml with your server's public IP and SSH key

# If using Ansible Vault, add --ask-vault-pass to the command
ansible-playbook playbook.yml
```

## Configuration

### Terraform Variables

Create `terraform/terraform.tfvars`:

```hcl
tenancy_ocid     = "ocid1.tenancy.oc1..your_tenancy_ocid"
user_ocid        = "ocid1.user.oc1..your_user_ocid"
fingerprint      = "your_api_key_fingerprint"
private_key_path = "~/.oci/oci_api_key.pem"
region           = "us-ashburn-1"
compartment_id   = "ocid1.compartment.oc1..your_compartment_ocid"
ssh_public_key_path = "~/.ssh/oci_ptero.pub"
vm_name          = "pterodactyl-arm"
```

### Ansible Variables

Edit `ansible/group_vars/all.yml` (or use `ansible-vault edit group_vars/all.yml` if using Ansible Vault):

```yaml
# Database Configuration
db_mysql_database: "panel"
db_mysql_user: "pterodactyl"
db_mysql_password: "your_secure_mysql_password"
db_redis_password: "your_secure_redis_password"

# Panel Configuration
panel_pterodactyl_panel_user: "pterodactyl"
panel_app_key: "your_base64_encoded_app_key"
panel_hashids_salt: "your_hashids_salt_value"
panel_base_fqdn: "yourdomain.com"
panel_pterodactyl_domain: "https://ptero.{{ panel_base_fqdn }}" # Automatically set based on base FQDN. You also can set this to a specific subdomain if needed
panel_wings_fqdn: "https://wings1.{{ panel_base_fqdn }}" # Automatically set based on base FQDN

# SSL Configuration
panel_cloudflare_api_token: "your_cloudflare_api_token"
panel_certbot_email: "admin@yourdomain.com"

# MCRouter Configuration
mcrouter_mappings:
  - domain: mc1.yourdomain.com
    port: 25566
  - domain: mc2.yourdomain.com
    port: 25567
```

You can generate the `panel_app_key` using:

```bash
php artisan key:generate --force --show
```
in a local Pterodactyl Panel directory or let panel generate it during the deployment.


If you don't need MCRouter, you can comment it out in the playbook and not include the configuration in `group_vars/all.yml`.

Update `ansible/inventory/hosts.yml`:

```yaml
all:
  hosts:
    pterodactyl:
      ansible_host: your_server_public_ip
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/oci_ptero
```

## Post-Deployment Setup

### 1. Create Admin User

After deployment, create your first admin user for the Pterodactyl Panel:

```bash
docker exec -it panel php artisan p:user:make
```

### 2. Configure Firewall

Ensure the following ports are open in your OCI security list and firewall:

- **80/443** - HTTP/HTTPS (Panel access)
- **8080** - Wings daemon
- **2022** - Wings SFTP
- **25565** - Minecraft game servers (routing is domain-based, via MCRouter)

### 3. Wings Configuration

1. Log into your Pterodactyl Panel
2. Go to Admin → Nodes → Create New
3. Configure the node with your Wings FQDN
4. Copy the generated configuration to `/etc/pterodactyl/config.yml`
5. If needed, adjust the Wings configuration for your specific setup. You can find Caddy's certificate and key paths in `/opt/caddy/data/caddy/certificates` if you choose to use SSL with Wings.
6. Restart Wings: `systemctl restart wings`

## Project Structure

```
├── terraform/           # Infrastructure as Code
│   ├── instance.tf      # VM instance configuration
│   ├── networking.tf    # VPC, subnets, security rules
│   ├── variables.tf     # Input variables
│   └── outputs.tf       # Output values
└── ansible/             # Configuration Management
    ├── playbook.yml     # Main deployment playbook
    ├── group_vars/      # Global variables
    ├── inventory/       # Host inventory
    └── roles/           # Ansible roles
        ├── db/          # MySQL & Redis containers
        ├── caddy/       # Caddy reverse proxy
        ├── panel/       # Pterodactyl Panel
        ├── wings/       # Pterodactyl Wings daemon
        └── mcrouter/    # Minecraft proxy
```

## License

This project is provided as-is for educational and deployment purposes. See the [LICENSE](LICENSE.md) file for details.
