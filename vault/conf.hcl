ui = true

storage "file" {
  path = "/vault/file"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  # tls is handled by a reverse nginx proxy
  tls_disable = 1
}
