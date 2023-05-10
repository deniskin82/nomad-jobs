job "redis" {
  datacenters = ["local"]

  group "redis-group" {
    network {
      mode = "cni/bridge"
      port "redis" {
        to = 6379
      }
    }
    task "redis-task" {
      driver = "containerd-driver"

      config {
        image = "docker.io/library/redis:alpine"
      }

      service {
        tags = ["global","redis"]

        name     = "redis"
        port     = "redis"
        provider = "consul"

        check {
          name     = "redis port alive"
          type     = "tcp"
          port     = "redis"
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
