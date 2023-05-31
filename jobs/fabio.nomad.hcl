job "fabio" {
  datacenters = ["local"]

  group "fabio" {
    network {
      mode = "host"

      port "http" {
        static = 80
      }
      port "https" {
        static = 443
      }
      port "ui" {
        static = 9998
      }
    }

    service {
      name = "lb"
      tags = ["fabio"]
      port = "http"

      check {
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name = "lb"
      tags = ["fabio"]
      port = "https"

      check {
        type     = "tcp"
        port     = "https"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name = "fabio-ui"
      tags = ["fabio"]
      port = "ui"

      check {
        type     = "http"
        port     = "ui"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "fabio" {
      driver = "containerd-driver"

      config {
        image   = "mirror.service.consul:5001/fabiolb/fabio:latest"
        host_network = true
        args = [
          "-registry.consul.addr=https://consul.service.consul:8501/",
          "-registry.consul.tls.insecureskipverify=true",
          "-proxy.addr=:80,:443;proto=tcp+sni",
          "-proxy.shutdownwait=30s",
          "-insecure"
        ]
      }

      resources {
        cpu    = 1000
        memory = 70
      }
    }
  }
}
