provider "nomad" {
  address = "https://nomad.service.consul:4646"
  region  = "global"
  ca_file = var.ca_file
}

provider "consul" {
  address    = "consul.service.consul:8501"
  scheme     = "https"
  datacenter = "local"
  ca_file    = var.ca_file
}

resource "consul_keys" "mounts" {
  datacenter = "local"

  key {
    path  = "mount/data/volumes/netdata_cache"
    value = ""
  }
  key {
    path = "mount/data/volumes/netdata_data"
    value = ""
  }
  key {
    path = "mount/data/volumes/jellyfin/cache"
    value = ""
  }
  key {
    path = "mount/data/volumes/jellyfin/config"
    value = ""
  }
  key {
    path = "mount/data/volumes/docker_registry/cache"
    value = ""
  }
  key {
    path = "mount/data/volumes/docker_registry/data"
    value = ""
  }
  key {
    path = "mount/data/volumes/cicd/postgres"
    value = ""
  }
}

resource "consul_keys" "docker" {
  datacenter = "local"

  key {
    path  = "docker/mirror/crt"
    value = join("",[file(var.docker_cert),file(var.ca_file)])
  }
  key {
    path  = "docker/mirror/key"
    value = file(var.docker_key)
  }
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
  depends_on = [
    consul_keys.docker
  ]
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
