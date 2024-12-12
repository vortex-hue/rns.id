# main.tf

# Database cluster configuration with high availability
resource "digitalocean_database_cluster" "postgres" {
  name       = "${var.project_name}-db"
  engine     = "pg"
  version    = "15"
  size       = "db-s-1vcpu-2gb"  # Keep the existing size
  region     = var.region
  node_count = 2
}

# Create database
resource "digitalocean_database_db" "app_database" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = var.project_name
}

# Create database user
resource "digitalocean_database_user" "app_user" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = "${var.project_name}_user"
}

# Grant necessary permissions using a null_resource
resource "null_resource" "grant_permissions" {
  depends_on = [digitalocean_database_user.app_user, digitalocean_database_db.app_database]

  provisioner "local-exec" {
    command = <<-EOT
      PGPASSWORD=${digitalocean_database_cluster.postgres.password} psql \
      -h ${digitalocean_database_cluster.postgres.host} \
      -p ${digitalocean_database_cluster.postgres.port} \
      -U ${digitalocean_database_cluster.postgres.user} \
      -d ${digitalocean_database_db.app_database.name} \
      -c 'GRANT ALL ON SCHEMA public TO ${digitalocean_database_user.app_user.name};' \
      -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${digitalocean_database_user.app_user.name};' \
      -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${digitalocean_database_user.app_user.name};'
    EOT
  }
}


# Create connection pools for better load balancing
resource "digitalocean_database_connection_pool" "pool_reads" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = "read-pool"
  mode       = "transaction"
  size       = 25
  db_name    = digitalocean_database_db.app_database.name
  user       = digitalocean_database_user.app_user.name
}

resource "digitalocean_database_connection_pool" "pool_writes" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = "write-pool"
  mode       = "transaction"
  size       = 10
  db_name    = digitalocean_database_db.app_database.name
  user       = digitalocean_database_user.app_user.name
}

# App Platform configuration
resource "digitalocean_app" "app" {
  spec {
    name   = var.project_name
    region = var.region

    database {
      name         = "${var.project_name}-db"
      engine       = "PG"
      cluster_name = digitalocean_database_cluster.postgres.name
      production   = true
    }

    service {
      name               = "${var.project_name}-service"
      instance_size_slug = "basic-xxs" #If you want to scale, please change the instance_size_slug first, before the  instance_count
      instance_count     = 1
      http_port          = var.port

      git {
        repo_clone_url = "https://github.com/vortex-hue/kurudy.git"
        branch         = "main"
      }

      run_command = "npm start"

      # Environment variables for database connections
      env {
        key   = "DB_HOST"
        value = digitalocean_database_cluster.postgres.host
        type  = "SECRET"
      }
      env {
        key   = "DB_USER"
        value = digitalocean_database_user.app_user.name
        type  = "SECRET"
      }
      env {
        key   = "DB_PASSWORD"
        value = digitalocean_database_user.app_user.password
        type  = "SECRET"
      }
      env {
        key   = "DB_NAME"
        value = digitalocean_database_db.app_database.name
        type  = "SECRET"
      }
      env {
        key   = "DB_PORT"
        value = digitalocean_database_cluster.postgres.port
        type  = "SECRET"
      }
      env {
        key   = "DB_READ_HOST"
        value = digitalocean_database_connection_pool.pool_reads.host
        type  = "SECRET"
      }
      env {
        key   = "DB_WRITE_HOST"
        value = digitalocean_database_connection_pool.pool_writes.host
        type  = "SECRET"
      }
      
      # AWS environment variables
      env {
        key   = "AWS_ACCESS_KEY_ID"
        value = var.aws_access_key_id
        type  = "SECRET"
      }
      env {
        key   = "AWS_SECRET_ACCESS_KEY"
        value = var.aws_secret_access_key
        type  = "SECRET"
      }
      env {
        key   = "AWS_REGION"
        value = var.aws_region
        type  = "SECRET"
      }
      env {
        key   = "S3_BUCKET"
        value = var.s3_bucket
        type  = "SECRET"
      }
      env {
        key   = "PORT"
        value = var.port
        type  = "SECRET"
      }
      env {
        key   = "HOST"
        value = var.host
        type  = "SECRET"
      }
    }
  }
}