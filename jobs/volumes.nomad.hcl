job "volumes" {
  datacenters = ["local"]
  type = "system"
  priority = 99

  group "services" {
    task "volumes" {
      driver = "containerd-driver"
      template {
        perms = "755"
        data = <<EOH
#!/bin/sh
set -e
{{ range tree "mount/data/volumes" }}mkdir -v -m777 -p /volumes/./{{.Key}}
chmod -v 0777 /volumes/./{{.Key}}
{{ end }}sleep 3
date
EOH
        destination = "local/mkdirs.sh"
        change_mode = "restart"
      }

      config {
        image = "alpine:3.18.0"
        mounts = [
          {
          type    = "bind"
          source  = "/data/volumes/"
          target  = "/volumes"
          options = ["rbind", "rw"]
          }
        ]
        command = "sh"
        args = ["-c", "/bin/sh local/mkdirs.sh; while true; do sleep 10; done"]
      }
      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
