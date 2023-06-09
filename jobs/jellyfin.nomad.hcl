job "dlna" {
  datacenters = ["local"]
  priority = 30

  group "services" {
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
        image = "mirror.service.consul:5001/jellyfin/jellyfin:10.8.10"
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
        tags = ["jellyfin","urlprefix-/web"]

        name     = "jellyfin"
        port     = "jellyfin"
        provider = "consul"

        check {
          name     = "jellyfin healthcheck"
          type     = "http"
          port     = "jellyfin"
          path     = "/health"
          interval = "30s"
          timeout  = "3s"
        }
      }

      resources {
        cpu    = 2300
        memory = 1400
      }
    }
  }
}
