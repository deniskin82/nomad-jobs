provider "nomad" {
  address = "https://nomad.service.consul:4646"
  region  = "global"
  cert_file = "../vault/local/tls/nomad.crt"
  key_file = "../vault/local/tls/nomad-key.pem"
  ca_file = var.ca_file
}

resource "nomad_job" "volumes" {
  jobspec = file("${path.module}/jobs/volumes.nomad.hcl")
  detach = false
  hcl2 {
    enabled = true
    allow_fs = true
  }
}

resource "nomad_job" "registry" {
  jobspec = file("${path.module}/jobs/registry.nomad.hcl")
  detach = false
  hcl2 {
    enabled = true
    allow_fs = true
  }
}

resource "nomad_job" "jellyfin" {
  jobspec = file("${path.module}/jobs/jellyfin.nomad.hcl")
  detach = false
  hcl2 {
    enabled = true
    allow_fs = true
  }
}

resource "nomad_job" "netdata" {
  jobspec = file("${path.module}/jobs/netdata.nomad.hcl")
  detach = false
  hcl2 {
    enabled = true
    allow_fs = true
  }
}
