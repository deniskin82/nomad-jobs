job "dlna" {
  datacenters = ["dc1"]

  group "dlna-group" {
    network {
      mode = "host"
      port "jellyfin" {
        static = 8096
        to = 8096
      }

      port "dlna" {
        static = 1900
        to = 1900
      }
    }

    task "jellyfin" {
      driver = "containerd-driver"

      config {
        image = "docker.io/jellyfin/jellyfin:10.8.10"
        host_network = true
        hostname = "jellyfin"
        mounts = [{
          type    = "bind"
          source  = "/data/volumes/jellyfin/config"
          target  = "/config"
          options = ["rbind", "rw"]
        },{
          type    = "bind"
          source  = "/data/volumes/jellyfin/cache"
          target  = "/cache"
          options = ["rbind", "rw"]
        },{
          type    = "bind"
          source  = "/mnt/media"
          target  = "/media"
          options = ["rbind", "ro"]
        }]
      }

      env {
        DOTNET_CLI_TELEMETRY_OPTOUT = "1"
      }

      service {
        tags = ["jellyfin"]

        name     = "jellyfin"
        port     = "jellyfin"
        provider = "consul"

        check {
          name     = "jellyfin port alive"
          type     = "tcp"
          port     = "jellyfin"
          interval = "30s"
          timeout  = "3s"
        }
      }

      resources {
        cpu    = 1300
        memory = 1000
      }
    }
  }
}
