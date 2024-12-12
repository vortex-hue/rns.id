# RNS.ID | Infrastructure Technical Documentation: Listing Service Deployment

_NB_ This is for my DevOps trial, you can checkout the live deployed version with terraform via [rns.id devops](https://rnsid-tobhp.ondigitalocean.app/docs/)

## Overview

This document outlines the infrastructure setup for the Listing Service using Terraform to automate the deployment of database, application, and load balancing components on DigitalOcean's platform.

## Architecture Components

### 1. Database Layer

- **PostgreSQL Managed Database**
  - High-availability cluster with 2 nodes
  - Size: db-s-1vcpu-2gb
  - Automatic failover
  - Built-in load balancing between nodes
  - Connection pooling for read/write operations

### 2. Application Layer (App Platform/Cloud Run equivalent)

- **DigitalOcean App Platform**
  - 3 application instances for horizontal scaling
  - Automatic load balancing between instances
  - Size: basic-xxs
  - Git-based deployment from repository
  - Environment variables management
  - Health checks and automatic restarts

### 3. Load Balancing

- **Database Load Balancing**
  - Primary-replica architecture
  - Connection pools:
    - Read pool (25 connections)
    - Write pool (10 connections)
  - Transaction-based connection management

## Infrastructure as Code (Terraform)

### Resource Organization

```hcl
├── main.tf           # Main infrastructure definitions
├── variables.tf      # Variable declarations
├── outputs.tf        # Output definitions
└── terraform.tfvars  # Variable values
```

### Key Resources

1. **Database Cluster**

```hcl
resource "digitalocean_database_cluster" "postgres" {
  name       = "${var.project_name}-db"
  engine     = "pg"
  version    = "15"
  size       = "db-s-1vcpu-2gb"
  region     = var.region
  node_count = 2
}
```

2. **Application Platform**

```hcl
resource "digitalocean_app" "app" {
  spec {
    service {
      name            = "${var.project_name}-service"
      instance_count  = 3
      instance_size_slug = "basic-xxs"
    }
  }
}
```

3. **Connection Pools**

```hcl
resource "digitalocean_database_connection_pool" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = "read-pool"
  mode       = "transaction"
  size       = 25
}
```

## Deployment Process

### 1. Infrastructure Initialization

```bash
terraform init
```

- Initializes Terraform working directory
- Downloads required providers
- Sets up backend state

### 2. Configuration Validation

```bash
terraform plan
```

- Validates configuration
- Shows planned changes
- Checks for potential issues

### 3. Infrastructure Deployment

```bash
terraform apply
```

- Creates/updates all resources
- Sets up database connections
- Configures environment variables
- Deploys application instances

## Security Considerations

### Database Security

- Private networking between components
- Encrypted connections (TLS)
- User-level permissions management
- Connection pooling for resource protection

### Application Security

- Environment variables stored as secrets
- Automated certificate management
- Secure service-to-service communication

## Environment Variables

The following environment variables are automatically configured:

```
db_host         = [Database endpoint]
db_user         = [Database username]
db_password     = [Database password]
db_name         = [Database name]
db_port         = [Database port]
db_read_host    = [Read pool endpoint]
db_write_host   = [Write pool endpoint]
```

## Scaling Considerations

### Vertical Scaling

- Database: Can be upgraded to larger instance sizes
- Application: Instance size can be modified based on load

### Horizontal Scaling

- Database: Managed through read replicas
- Application: Instance count can be increased
- Load Balancing: Automatically adjusts to instance changes

## Monitoring and Maintenance

### Available Metrics

- Database connection counts
- Query performance
- Application instance health
- Load balancer distribution

### Maintenance Tasks

- Database backups: Automated daily
- Version upgrades: Managed through Terraform
- Security patches: Automatically applied

## Common Operations

### Scaling Application Instances

```hcl
# Modify instance_count in main.tf
service {
  instance_count = 5  # Increase from 3 to 5
}
```

### Database User Management

```hcl
# Add new database user
resource "digitalocean_database_user" "new_user" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = "new_user_name"
}
```

## Troubleshooting

### Common Issues and Solutions

1. **Database Connection Issues**

   - Check connection pool settings
   - Verify network connectivity
   - Validate user permissions

2. **Application Deployment Failures**

   - Review environment variables
   - Check application logs
   - Verify resource constraints

3. **Load Balancing Problems**
   - Monitor instance health
   - Check connection distribution
   - Verify pool configurations

## Best Practices

1. **Infrastructure Management**

   - Use workspaces for different environments
   - Maintain state file backups
   - Document all custom configurations

2. **Security**

   - Rotate credentials regularly
   - Use least privilege access
   - Monitor security alerts

3. **Scaling**
   - Monitor resource utilization
   - Plan capacity ahead
   - Test scaling configurations

## Version Control

### Infrastructure Version

- Terraform: >= 1.0
- Provider Versions:
  - DigitalOcean: ~> 2.0
  - PostgreSQL: >= 15

### Application Version

- Node.js application
- Git repository: https://github.com/vortex-hue/kurudy.git

## Support and Resources

- DigitalOcean Documentation
- Terraform Registry
- Application Documentation
- Infrastructure Team Contacts

## Conclusion

This infrastructure setup provides a scalable, maintainable, and secure environment for the Listing Service. Through Terraform automation, the entire infrastructure can be consistently deployed and managed with minimal manual intervention.
