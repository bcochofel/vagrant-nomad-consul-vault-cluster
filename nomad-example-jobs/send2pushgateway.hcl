job "send2pushgateway" {
  datacenters = ["dc1"]
  type = "batch"

  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }

  periodic {
    // Launch every 20 seconds
    cron = "@hourly"

    // Do not allow overlapping runs.
    prohibit_overlap = true
  }

  group "send2pushgateway" {
    count = 1

    restart {
      interval = "20s"
      attempts = 2
      delay    = "5s"
      mode     = "delay"
    }

    task "send2pushgateway" {
      driver = "exec"

      config {
        command = "send2pushgateway.sh"
      }

      artifact {
        source = "https://raw.githubusercontent.com/bcochofel/vagrant-ansible-devops/master/nomad-consul-cluster/nomad-example-jobs/scripts/send2pushgateway.sh"
      }
    }
  }
}
