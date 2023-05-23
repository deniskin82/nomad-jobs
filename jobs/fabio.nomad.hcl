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
      // port "lb" {
      //   static = 9999
      // }
    }

    service {
      name = "fabio-lb"
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

    service {
      name = "fabio-lb-tls"
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
        type     = "tcp"
        port     = "ui"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "fabio" {
      driver = "containerd-driver"

      config {
        image   = "fabiolb/fabio"
        host_network = true
        args = [
          "-registry.consul.addr=http://consul.service.consul:8500/",
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