provider "nomad" {
  address = "https://nomad.service.consul:4646"
  region  = "global"
  ca_file = var.ca_file
}

resource "nomad_job" "volumes" {
  jobspec = file("${path.module}/jobs/volumes.nomad.hcl")
  detach = false
  hcl2 {
    enabled = true
    allow_fs = true
  }
  purge_on_destroy = true
}

resource "nomad_job" "registry" {
  jobspec = file("${path.module}/jobs/registry.nomad.hcl")
  detach = false
  hcl2 {
    enabled = true
    allow_fs = true
  }
  purge_on_destroy = true
}

resource "nomad_job" "jellyfin" {
  jobspec = file("${path.module}/jobs/jellyfin.nomad.hcl")
  detach = false
  hcl2 {
    enabled = true
    allow_fs = true
  }
  depends_on = [
    nomad_job.registry
  ]
  purge_on_destroy = true
}

resource "nomad_job" "netdata" {
  jobspec = file("${path.module}/jobs/netdata.nomad.hcl")
  detach = false
  hcl2 {
    enabled = true
    allow_fs = true
  }
  depends_on = [
    nomad_job.registry
  ]
  purge_on_destroy = true
}

resource "nomad_job" "fabio" {
  jobspec = file("${path.module}/jobs/fabio.nomad.hcl")
  detach = false
  hcl2 {
    enabled = true
    allow_fs = true
  }
  depends_on = [
    nomad_job.registry
  ]
  purge_on_destroy = true
}
