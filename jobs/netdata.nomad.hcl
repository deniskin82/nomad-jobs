job "netdata" {
  datacenters = ["local"]
  priority = 70

  group "netdata" {
    network {
      mode = "cni/bridge"
      port "netdata" {
        static = 19999
        to = 19999
      }
    }
    task "netdata-task" {
      driver = "containerd-driver"
      env {
        DISABLE_TELEMETRY = "1"
        TZ = "America/New_York"
        PUID = 1000
        PGID = 1000
      }
      config {
        image = "mirror.service.consul:5001/netdata/netdata:v1.39.1"
        cap_add = [
          "SYS_PTRACE"
        ]
        mounts = [{
          type    = "bind"
          source  = "/proc"
          target  = "/host/proc"
          options = ["rbind", "ro"]
        },{
          type    = "bind"
          source  = "/sys"
          target  = "/host/sys"
          options = ["rbind", "ro"]
        },{
          type    = "bind"
          source  = "/run/containerd/containerd.sock"
          target  = "/host/run/containerd/containerd.sock"
          options = ["rbind", "ro"]
        },{
          type    = "bind"
          source  = "/etc/os-release"
          target  = "/host/etc/os-release"
          options = ["rbind", "ro"]
        },{
          type    = "bind"
          source  = "/data/volumes/netdata_cache"
          target  = "/var/cache/netdata"
          options = ["rbind", "rw"]
        },{
          type    = "bind"
          source  = "/data/volumes/netdata_data"
          target  = "/var/lib/netdata"
          options = ["rbind", "rw"]
        }]
      }

      service {
        tags = ["urlprefix-/netdata strip=/netdata","global","netdata"]

        name     = "netdata"
        port     = "netdata"
        provider = "consul"

        check {
          name     = "netdata port alive"
          type     = "tcp"
          port     = "netdata"
          interval = "30s"
          timeout  = "3s"
        }
      }

      resources {
        cpu    = 500
        memory = 256
        network {
          mbits = 10
        }
      }
    }
  }
}
