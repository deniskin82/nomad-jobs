job "docker-registry" {
  datacenters = ["local"]

  group "docker-registry" {
    network {
      mode = "cni/bridge"
      port "docker" {
        static = 5000
      }

      port "ui" {
        static = 8080
        to = 80
      }
    }

    service {
      name = "registry"
      tags = ["hub"]
      port = "docker"

      check {
        type     = "tcp"
        port     = "docker"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name = "registry"
      tags = ["ui"]
      port = "ui"

      check {
        type     = "tcp"
        port     = "ui"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "registry" {
      driver = "containerd-driver"

      config {
        image = "registry:2.8.1"
        mounts = [{
          type    = "bind"
          source  = "/data/volumes/docker_registry/data"
          target  = "/data"
          options = ["rbind", "rw"]
        }]
      }

      env {
        REGISTRY_HTTP_ADDR = "0.0.0.0:${NOMAD_PORT_docker}"
        REGISTRY_STORAGE_DELETE_ENABLED = "true"
        REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY = "/data"
        REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR = "inmemory"
        REGISTRY_HTTP_HEADERS_X-Content-Type-Options = "[nosniff]"
        REGISTRY_HTTP_HEADERS_Access-Control-Allow-Origin = "['*']"
        REGISTRY_HTTP_HEADERS_Access-Control-Expose-Headers = "['Docker-Content-Digest']"
        REGISTRY_HTTP_HEADERS_Access-Control-Allow-Methods = "['HEAD', 'GET', 'OPTIONS', 'DELETE']"
        REGISTRY_HTTP_HEADERS_Access-Control-Allow-Headers = "['Authorization', 'Accept', 'Cache-Control']"
        REGISTRY_HTTP_HEADERS_Access-Control-Allow-Credentials = "[true]"
        REGISTRY_HEALTH_STORAGEDRIVER_ENABLED = "true"
        REGISTRY_HEALTH_STORAGEDRIVER_INTERVAL = "10s"
        REGISTRY_HEALTH_STORAGEDRIVER_THRESHOLD = "3"
        TZ = "America/New_York"
      }

      resources {
        cpu    = 400
        memory = 312
      }
    }

    task "ui" {
      driver = "containerd-driver"
      // https://github.com/Joxit/docker-registry-ui
      config {
        image = "joxit/docker-registry-ui:latest"
      //  command = "env"
      }

      env {
        REGISTRY_TITLE = "My Private Docker Registry"
        REGISTRY_URL = "http://${NOMAD_HOST_ADDR_docker}"
        DELETE_IMAGES = "true"
        TZ = "America/New_York"
        SINGLE_REGISTRY = "true"
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
