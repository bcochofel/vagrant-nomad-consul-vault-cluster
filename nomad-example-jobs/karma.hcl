job "karma" {
  datacenters = ["dc1"]
  type = "service"

  group "karma" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "karma" {
      artifact {
        source      = "https://raw.githubusercontent.com/bcochofel/vagrant-ansible-devops/master/karma/karma.yaml"
        destination = "local/karma.yaml.tpl"
        mode        = "file"
      }

      template {
        source        = "local/karma.yaml.tpl"
        destination   = "etc/karma/karma.yaml"
        change_mode   = "noop"
        change_signal = "SIGINT"
      }

      driver = "docker"

      config {
        image = "lmierzwa/karma:v0.43"
        network_mode = "host"

        dns_servers = ["${NOMAD_IP_http}", "8.8.8.8", "8.8.8.4"]

        port_map {
          http = 8080
        }

        volumes = [
          "etc/karma/karma.yaml:/karma.yaml"
        ]
      }

      resources {
        cpu    = 100 # MHz
        memory = 128 # 128MB

        network {
          mbits = 10
          port "http" {
            static = "8080"
          }
        }
      }

      service {
        name = "karma"
        tags = ["traefik.enable=true"]
        port = "http"

        check {
          name     = "http port alive"
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
