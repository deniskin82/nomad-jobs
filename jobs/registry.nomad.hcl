job "docker" {
  datacenters = ["local"]
  priority = 90

  group "mirror" {
    network {
      mode = "host"
      port "mirror" {
        static = 5001
      }
    }

    service {
      name = "mirror"
      tags = ["mirror","urlprefix-/mirror strip=/mirror"]
      port = "mirror"

      check {
        type     = "tcp"
        port     = "mirror"
        interval = "30s"
        timeout  = "5s"
      }
    }
    task "registry" {
      driver = "containerd-driver"

      config {
        image = "docker.io/registry:2.8.2"
        host_network = true
        mounts = [{
          type    = "bind"
          source  = "/data/volumes/docker_registry/cache"
          target  = "/data"
          options = ["rbind", "rw"]
        }]
      }
      template {
        data = <<EOF
{{ key "docker/mirror/crt" }}
EOF
        destination = "${NOMAD_SECRETS_DIR}/tls/docker.crt"
      }
      template {
        data = <<EOF
{{ key "docker/mirror/key" }}
EOF
        destination = "${NOMAD_SECRETS_DIR}/tls/docker.key"
      }

      env {
        REGISTRY_HTTP_ADDR = "0.0.0.0:${NOMAD_PORT_mirror}"
        REGISTRY_HTTP_TLS_CERTIFICATE = "${NOMAD_SECRETS_DIR}/tls/docker.crt"
        REGISTRY_HTTP_TLS_KEY = "${NOMAD_SECRETS_DIR}/tls/docker.key"
        REGISTRY_PROXY_REMOTEURL = "https://registry-1.docker.io"
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
        cpu    = 1400
        memory = 512
      }
    }
  }

  group "local" {
    network {
      mode = "cni/bridge"
      port "docker" {
        static = 5000
      }

      port "ui" {
        static = 8081
        to = 80
      }
    }

    service {
      name = "registry"
      tags = ["hub","urlprefix-/hub strip=/hub"]
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
      tags = ["ui","urlprefix-/docker-ui strip=/docker-ui"]
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
        image = "docker.io/registry:2.8.2"
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
        image = "docker.io/joxit/docker-registry-ui:latest"
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
