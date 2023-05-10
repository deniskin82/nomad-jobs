job "nginx" {
  datacenters = ["dc1"]

  group "nginx" {
    network {
      mode = "cni/bridge"
      port "http" {
        static = 80
        to = 80
      }
    }

    task "nginx" {
      driver = "containerd-driver"
    
      service {
        tags = ["global","nginx"]

        name     = "nginx"
        port     = "http"
        provider = "consul"

        check {
          name     = "http port alive"
          type     = "tcp"
          port     = "http"
          interval = "30s"
          timeout  = "2s"
        }
      }
      
      config {
        image = "nginx:latest"
      }
    }
  }
}
