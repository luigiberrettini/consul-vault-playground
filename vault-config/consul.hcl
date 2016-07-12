backend "consul" {
    address = "consul:8500"
    path = "vault_std_own_consul"
    advertise_addr = "http://active.vault.service.consul:8200"
}

listener "tcp" {
    address = "0.0.0.0:8200"
    tls_disable = 1
}

disable_mlock = true