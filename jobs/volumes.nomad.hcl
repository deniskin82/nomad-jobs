job "volumes" {
  datacenters = ["local"]
  type = "sysbatch"
  periodic {
    cron             = "@daily"
    prohibit_overlap = true
    time_zone        = "America/New_York"
  }

  group "volume" {
    task "volumes" {
      driver = "raw_exec"
      template {
        perms = "755"
        data = <<EOH
#!/bin/sh
set -xe
{{ range tree "mount/data/volumes" }}mkdir -v -m777 -p /data/volumes/./{{.Key}}
chmod 0777 /data/volumes/./{{.Key}}
{{ end }}sleep 3
EOH
        destination = "tmp/mkdirs.sh"
      }
      config {
        command = "/bin/sh"
        args = ["tmp/mkdirs.sh"]
      }
      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
