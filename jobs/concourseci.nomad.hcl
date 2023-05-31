job "concourse" {
  datacenters = ["local"]
  priority = 60

  group "cicd" {
    count = 1
    network {
      mode = "cni/bridge"
      port "db" {
        static = 5432
        to = 5432
      }
      port "http" {
        static = 8080
        to = 8080
      }
      port "tsa" {
        static = 2222
        to = 2222
      }
      port "worker" {
        static = 7777
        to = 7777
      }
      port "baggageclaim" {
        static = 7788
        to = 7788
      }
    }

    task "postgres" {
      driver = "containerd-driver"
      config {
        image = "mirror.service.consul:5001/library/postgres:15.3-alpine3.17"

        mounts = [
          {
          type    = "bind"
          source  = "/data/volumes/cicd/postgres"
          target  = "/database"
          options = ["rbind", "rw"]
          }
        ]
      }

      env {
        POSTGRES_USER="{{ key \"concourse/db/user\" }}"
        POSTGRES_PASSWORD="{{ key \"concourse/db/password\" }}"
        PGDATA="/database"
        POSTGRES_DB="concourse"
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }

      resources {
        cpu = 1000
        memory = 1024
        network {
          mbits = 10
        }
      }
      service {
        name = "ci-db"
        tags = ["pg"]
        port = "db"
        provider = "consul"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

    // task "task1" {
    //   driver = "exec"

    //   config {
    //     command = "env"
    //   }
    // }

    task "concourse-web" {
      driver = "containerd-driver"

      config {
        image = "mirror.service.consul:5001/concourse/concourse"
        command = "web"
      }
      template {
        data = <<EOF
{{ key "concourse/web/session_signing_key" }}
EOF
        destination = "${NOMAD_SECRETS_DIR}/session_signing_key"
      }
      template {
        data = <<EOF
{{ range tree "concourse/workers/" }}
{{.Value}}{{end}}
EOF
        destination = "local/authorized_worker_keys"
        change_mode = "signal"
        change_signal = "SIGHUP"
      }
      template {
        data = <<EOF
{{ key "concourse/web/tsa_host_key_pub" }}
EOF
        destination = "${NOMAD_SECRETS_DIR}/tsa_host_key.pub"
      }
      template {
        data = <<EOF
{{ key "concourse/web/tsa_host_key" }}
EOF
        destination = "${NOMAD_SECRETS_DIR}/tsa_host_key"
      }
      template {
        data = <<EOF
CONCOURSE_LOG_LEVEL=error
CONCOURSE_POSTGRES_HOST={{env "NOMAD_HOST_IP_db"}}
CONCOURSE_POSTGRES_PORT={{env "NOMAD_HOST_PORT_db"}}
CONCOURSE_POSTGRES_DATABASE=concourse
CONCOURSE_POSTGRES_USER={{ key "concourse/db/user" }}
CONCOURSE_POSTGRES_PASSWORD={{ key "concourse/db/password" }}
CONCOURSE_EXTERNAL_URL=http://{{env "NOMAD_HOST_IP_http"}}:{{env "NOMAD_HOST_PORT_http"}}
CONCOURSE_ADD_LOCAL_USER=test:test,guest:guest
CONCOURSE_MAIN_TEAM_LOCAL_USER=test
CONCOURSE_WORKER_BAGGAGECLAIM_DRIVER=overlay
CONCOURSE_CLIENT_SECRET="{{ key "concourse/secrets/client" }}"
CONCOURSE_TSA_CLIENT_SECRET="{{ key "concourse/secrets/tsa" }}"
CONCOURSE_X_FRAME_OPTIONS=allow
CONCOURSE_CONTENT_SECURITY_POLICY="*"
CONCOURSE_CLUSTER_NAME="HomeLab"
CONCOURSE_ENABLE_PIPELINE_INSTANCES="true"
CONCOURSE_ENABLE_ACROSS_STEP="true"
CONCOURSE_ENABLE_CACHE_STREAMED_VOLUMES="true"
CONCOURSE_ENABLE_RESOURCE_CAUSALITY="true"
CONCOURSE_SESSION_SIGNING_KEY={{ env "NOMAD_SECRETS_DIR" }}/session_signing_key
CONCOURSE_TSA_HOST_KEY={{ env "NOMAD_SECRETS_DIR" }}/tsa_host_key
CONCOURSE_TSA_AUTHORIZED_KEYS=local/authorized_worker_keys
CONCOURSE_ENABLE_P2P_VOLUME_STREAMING="true"
CONCOURSE_ENABLE_PIPELINE_INSTANCES="true"
CONCOURSE_ENABLE_ACROSS_STEP="true"
CONCOURSE_ENABLE_CACHE_STREAMED_VOLUMES="true"
EOF
        destination = "${NOMAD_SECRETS_DIR}/data.env"
        env = true
      }
      service {
        name = "ci"
        port = "http"
        provider = "consul"
        tags = ["web","urlprefix-/ci strip=/ci"]

        check {
          name = "ci health check"
          type = "http"
          port = "http"
          path = "/api/v1/info"
          interval = "30s"
          timeout = "5s"
        }
      }
    }
    task "concourse-worker" {
      driver = "containerd-driver"

      config {
        image = "mirror.service.consul:5001/concourse/concourse"
        command = "worker"
        privileged = true
        mounts = [{
          type    = "bind"
          source  = "/sys/fs"
          target  = "/sys/fs"
          options = ["rbind", "ro"]
        }]
      }

      service {
        name = "ci-worker"
        tags = ["worker"]
        provider = "consul"

        check {
          name     = "garden"
          type     = "http"
          port     = "worker"
          path     = "/ping"
          interval = "10s"
          timeout  = "2s"
        }
        check {
          name     = "baggageclaim"
          type     = "http"
          port     = "baggageclaim"
          path     = "/volumes"
          interval = "10s"
          timeout  = "2s"
        }
      }
      template {
        data = <<EOF
{{ key "concourse/web/tsa_host_key_pub" }}
EOF
        destination = "${NOMAD_SECRETS_DIR}/tsa_host_key.pub"
      }
      template {
        data = <<EOF
{{ key "concourse/worker/private/test.key" }}
EOF
        destination = "${NOMAD_SECRETS_DIR}/worker.key"
      }
      template {
        data = <<EOF
CONCOURSE_LOG_LEVEL=error
CONCOURSE_TSA_HOST={{env "NOMAD_HOST_ADDR_tsa"}}
CONCOURSE_TSA_PUBLIC_KEY={{ env "NOMAD_SECRETS_DIR" }}/tsa_host_key.pub
CONCOURSE_TSA_WORKER_PRIVATE_KEY={{ env "NOMAD_SECRETS_DIR" }}/worker.key
CONCOURSE_GARDEN_DNS_PROXY_ENABLE="true"
CONCOURSE_BIND_IP=0.0.0.0
CONCOURSE_BAGGAGECLAIM_BIND_IP=0.0.0.0
CONCOURSE_BAGGAGECLAIM_DRIVER=overlay
CONCOURSE_WORKER_RUNTIME=containerd
CONCOURSE_RUNTIME=containerd
EOF
        destination = "local/data.env"
        change_mode = "restart"
        env = true
      }
    }
    // restart {
    //   attempts = 4
    //   interval = "5m"
    //   delay = "25s"
    //   mode = "delay"
    // }
  }

  // update {
  //   max_parallel = 1
  //   min_healthy_time = "5s"
  //   healthy_deadline = "3m"
  //   auto_revert = false
  //   canary = 0
  // }
}
