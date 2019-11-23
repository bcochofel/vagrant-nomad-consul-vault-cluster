job "cadvisor" {
  datacenters = ["dc1"]
  type = "system"

  group "cadvisor" {

    task "cadvisor" {
      driver = "docker"

      config {
        image = "google/cadvisor:v0.33.0"

        dns_servers = ["${NOMAD_IP_http}", "8.8.8.8", "8.8.8.4"]

        port_map {
          http = 8080
        }

        volumes = [
          "/:/rootfs:ro",
          "/var/run:/var/run:rw",
          "/sys:/sys:ro",
          "/var/lib/docker/:/var/lib/docker:ro",
          "/cgroup:/cgroup:ro"
        ]

        logging {
          type = "journald"
          config {
            tag = "CADVISOR"
          }
        }
      }

      service {
        name = "cadvisor"
        tags = ["prometheus", "traefik.enable=true"]
        port = "http"

        check {
          type = "http"
          path = "/"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        cpu    = 100 # 100 MHz
        memory = 32  # 32MB

        network {
          mbits = 100
          port "http" {
          }
        }
      }
    }
  }
}
