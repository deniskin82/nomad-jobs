job "volumes" {
  datacenters = ["local"]
  region = "global"
  type = "system"
  priority = 99

  group "services" {
    task "volumes" {
      driver = "raw_exec"
      template {
        perms = "755"
        data = <<EOH
#!/bin/sh
set -e
{{ range tree "mount/data/volumes" }}mkdir -v -m777 -p /data/volumes/./{{.Key}}
chmod -v 0777 /data/volumes/./{{.Key}}
{{ end }}sleep 3
date
EOH
        destination = "local/mkdirs.sh"
        change_mode = "restart"
      }
      config {
        command = "/bin/bash"
        args = ["-c", "/bin/sh local/mkdirs.sh; while true; do sleep 10; done"]
      }
      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
