job "prometheus" {
  datacenters = ["dc1"]
  type = "service"

  # All tasks in this job must run on linux.
  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "monitoring" {
    count = 1

    # tasks should run on distinct hosts
    constraint {
      distinct_hosts = true
    }

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    ephemeral_disk {
      size = 300
    }

    task "prometheus" {

      artifact {
        source      = "git::https://github.com/bcochofel/prometheus-configuration"
        destination = "local/repo"
      }

      template {
        source = "local/repo/prometheus-consul.yml"
        destination = "etc/prometheus/prometheus.yml"
        change_mode = "noop"
        change_signal = "SIGINT"
      }

      driver = "docker"

      config {
        image = "prom/prometheus:v2.12.0"
        network_mode = "host"

        dns_servers = ["${NOMAD_IP_http}", "8.8.8.8", "8.8.8.4"]

        port_map {
          http = 9090
        }

        args = [
          "--config.file=/etc/prometheus/prometheus.yml",
          "--storage.tsdb.retention.time=1d"
        ]

        volumes = [
          "local/repo/rules/:/etc/prometheus/",
          "etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml"
        ]
      }

      resources {
        cpu    = 200 # 200 MHz
        memory = 256 # 256MB

        network {
          mbits = 10

          port "http" {
            static = 9090
          }
        }
      }

      service {
        name = "prometheus"
        tags = ["prometheus", "traefik.enable=true"]
        port = "http"

        check {
          name     = "http port alive"
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
