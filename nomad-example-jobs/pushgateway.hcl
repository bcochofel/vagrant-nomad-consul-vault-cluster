job "pushgateway" {
  datacenters = ["dc1"]
  type = "service"

  group "pushgateway" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "pushgateway" {
      driver = "docker"

      config {
        image = "prom/pushgateway:v0.9.1"

        dns_servers = ["${NOMAD_IP_http}", "8.8.8.8", "8.8.8.4"]

        port_map {
          http = 9091
        }
      }

      resources {
        cpu    = 100 # 100 MHz
        memory = 128 # 128MB

        network {
          mbits = 10
          port "http" {
            static = "9091"
          }
        }
      }

      service {
        name = "pushgateway"
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
