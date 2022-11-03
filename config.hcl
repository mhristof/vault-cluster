listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true

}
storage "raft" {
  path = "/mikewashere"
}

disable_mlock = true

api_addr = "http://{{ GetPrivateIP }}:8200"
cluster_addr = "http://{{ GetPrivateIP }}:8201"
