output "app_url" {
  value = digitalocean_app.app.default_ingress
  description = "The URL of the deployed application"
}

output "database_cluster_id" {
  value = digitalocean_database_cluster.postgres.id
  description = "Database cluster ID"
}

output "database_connection_details" {
  value = {
    host     = digitalocean_database_cluster.postgres.host
    port     = digitalocean_database_cluster.postgres.port
    user     = digitalocean_database_user.app_user.name
    database = digitalocean_database_db.app_database.name
  }
  description = "Database connection details"
  sensitive   = true
}

output "database_connection_uri" {
  value       = digitalocean_database_cluster.postgres.uri
  description = "Database connection URI"
  sensitive   = true
}