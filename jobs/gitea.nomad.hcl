job "git" {
  datacenters = ["local"]
  priority = 55

  group "gitea" {
    network {
      mode = "cni/bridge"

      port "ssh" {
        static = 2222
      }
      port "git" {
        static = 3000
      }
    }

    service {
      name = "git"
      tags = ["gitea"]
      port = "git"

      check {
        type     = "tcp"
        port     = "git"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "git" {
      driver = "containerd-driver"
      env {
        DISABLE_TELEMETRY = "1"
        TZ = "America/New_York"
        PUID = 1000
        PGID = 1000
      }
      config {
        image   = "mirror.service.consul:5001/gitea/gitea:1.19.3-rootless"
        mounts = [{
          type    = "bind"
          source  = "/data/volumes/gitea/data"
          target  = "/var/lib/gitea"
          options = ["rbind", "rw"]
        },{
          type    = "bind"
          source  = "/data/volumes/gitea/config"
          target  = "/etc/gitea"
          options = ["rbind", "rw"]
        },{
          type    = "bind"
          source  = "/etc/localtime"
          target  = "/etc/localtime"
          options = ["rbind", "ro"]
        }]
      }

      resources {
        cpu    = 2000
        memory = 1024
      }
    }
  }
}
