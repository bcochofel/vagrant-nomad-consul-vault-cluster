# Provision a Nomad/Consul/Vault Cluster

## Introduction

Provision a Nomad/Consul/Vault cluster composed of one server and 3 clients using Vagrant and Ansible.

This project uses ansible roles from:

* https://galaxy.ansible.com/brianshumate/consul
* https://galaxy.ansible.com/brianshumate/nomad
* https://galaxy.ansible.com/brianshumate/vault
* https://galaxy.ansible.com/cloudalchemy/node-exporter
* https://galaxy.ansible.com/dj-wasabi/telegraf
* https://galaxy.ansible.com/kibatic/traefik

You should have at least the binary of ```vault``` on your path, but it's preferable to have also ```nomad```.

## Considerations

The default Vagrantfile deploys 4 VMs, 3 servers and 1 client. Here's the table with name's and ip's for the VMs:

| name     | ip            | os box             | type    |
| -------- | ------------- | ------------------ | ------- |
| manager  | 192.168.77.2  | bento/centos-7.7   | manager |
| server-1 | 192.168.77.10 | bento/ubuntu-18.04 | server  |
| server-2 | 192.168.77.11 | bento/ubuntu-18.04 | server  |
| server-3 | 192.168.77.12 | bento/centos-7.7   | server  |
| client-1 | 192.168.77.20 | bento/centos-7.7   | client  |

- m3db is deployed on manager;
- all the nodes created have docker, node_exporter and telegraf running;
- node_exporter service is registered on consul with health check and "prometheus" tag;
- telegraf service is registered on consul with health check and "prometheus" tag;
- m3 service is registered on consul with healt check and "prometheus" tag;
- consul cluster has telemetry enabled and also has a service so that prometheus can scrape metrics;
- vault uses only the servers group to create an HA cluster and also has telemetry enabled;
- nomad servers are also clients (this shouldn't be used in a production environment);
- prometheus configuration gets jobs from consul services with the tag "prometheus";
- all the nodes use dnsmasq to forward lookup of the 'consul' domain;
- traefik is deployed on server-1 and uses ```example.com```;

## Installation

The Vagrantfile has all the information for hosts and groups, as well as vars for Ansible playbooks, you just need to check for the last [Telegraf](https://portal.influxdata.com/downloads/) version and change ```TELEGRAF_VERSION``` variable.
If you want to add any host edit the following places:

* servers, clients and managers array
* ansible_groups, servers, clients and managers

After changing don't forget to validate the Vagrantfile:

```bash
vagrant validate
```

To create all the virtual machines and provision with the defaults execute:

```bash
ansible-galaxy install --roles-path ./ansible/roles -r requirements.yml

vagrant plugin install vagrant-hostmanager

vagrant up
```

You can also provision one or more steps using the following command if the VMs are already created:

```bash
vagrant provision --provision-with consul,nomad
```

Vault cluster is initialized and unseal on start-up.

For more information take a look at:

- https://learn.hashicorp.com/vault/getting-started/deploy
- https://learn.hashicorp.com/vault/day-one/ops-vault-ha-consul

After the installation is complete use the following URLs:

| URL                  | application |
| -------------------- | ----------- |
| http://server-1:8500 | consul ui   |
| http://server-1:4646 | nomad ui    |
| http://server-1:8200 | vault ui    |
| http://server-1:8081 | traefik ui  |
| http://manager:7201  | m3db ui     |

Take a look at ```nomad-job-examples``` for some job examples you can use on nomad.

If you want to use traefik add the following entries on ```/etc/hosts```:

- 192.168.77.10 grafana.example.com
- 192.168.77.10 alertmanager.example.com
- 192.168.77.10 karma.example.com
- 192.168.77.10 prometheus.example.com
- 192.168.77.10 pushgateway.example.com

## **Description**

### **Nomad Jobs**

The folder ```nomad-example-jobs``` has some jobspec files for the Prometheus monitoring stack.

You can run jobs from your workstation if you have the nomad binary installed. If you want to do this just
export the variable to connect to one of the nomad servers:

```bash
export NOMAD_ADDR=http://server-1:4646
```

After this you can run jobs using nomad binary from your workstation:

```bash
cd nomad-example-jobs
nomad run prometheus.hcl

nomad status prometheus
```

#### `Prometheus`

The Prometheus jobspec runs 1 allocation and has some constraints in case you want to change the count number:

- only runs on linux machines
- runs on distinct hosts

The configuration file ```prometheus.yml``` uses ```external_labels``` with the ```alloc_id``` variable from Nomad for HA. 

All the other configuration files can be used without changes on your Prometheus server(s).

The jobspec uses ```network_mode = "host"``` to use Consul DNS.

#### `Grafana`

The jobspec uses ```network_mode = "host"``` to use Consul DNS.

#### `Alertmanager`

#### `Pushgateway`

#### `Karma`

The jobspec uses ```network_mode = "host"``` to use Consul DNS.

## @TODO

* Improve Prometheus node_exporter/telegraf rules;
* Alertmanager for HA;
* Karma configuration for alertmanager HA;
* Nomad/Consul integration with Vault;
* Vault metrics for Prometheus and Consul integration;
* Karma metrics for Prometheus and Consul integration;
* Add support for [portwork](https://docs.portworx.com/install-with-other/nomad/) for stateful workloads;

## External Links

* [Consul Operations](https://learn.hashicorp.com/consul#operations-and-development)
* [Learn Nomad](https://learn.hashicorp.com/nomad)
* [Nomad Consul Integration](https://www.nomadproject.io/guides/integrations/consul-integration/index.html)
* [Nomad Vault Integration](https://www.nomadproject.io/docs/vault-integration/index.html)
* [Nomad Portwork Integration](https://www.nomadproject.io/guides/stateful-workloads/portworx.html)
* [Consul Envoy Integration](https://www.consul.io/docs/connect/proxies/envoy.html)
* [Using Prometheus to Monitor Nomad Metrics](https://www.nomadproject.io/guides/operations/monitoring-and-alerting/prometheus-metrics.html)
* [Blog Offensive Infrastructure Hashistack](https://www.marcolancini.it/2019/blog-offensive-infrastructure-hashistack/)
* [Alertmanager HA](https://prometheus.io/docs/alerting/alertmanager/#high-availability)
