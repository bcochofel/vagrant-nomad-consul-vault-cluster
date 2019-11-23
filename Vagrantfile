# -*- mode: ruby -*-
# vi: set ft=ruby :

### configuration parameters ###

# Vagrant variables
VAGRANTFILE_API_VERSION = "2"
DEFAULT_BOX_NAME = "bento/ubuntu-18.04"
DEFAULT_VM_RAM = "1024"
DEFAULT_VM_CPU = "1"

# hashicorp tools variables
CONSUL_VERSION = "1.6.0"
NOMAD_VERSION = "0.10.0"
VAULT_VERSION = "1.2.3"

# Telegraf version
TELEGRAF_VERSION = "1.12.6"

# Cluster Servers
servers = [
  { :hostname => 'server-1', :ip => '192.168.77.10', :ram => 2048, :cpus => 1 },
  { :hostname => 'server-2', :ip => '192.168.77.11', :ram => 2048, :cpus => 1 },
  { :hostname => 'server-3', :ip => '192.168.77.12', :ram => 2048, :cpus => 1, :box => "bento/centos-7.7" }
]

# ClusterClients
clients = [
  { :hostname => 'client-1', :ip => '192.168.77.20', :ram => 2048, :cpus => 1, :box => "bento/centos-7.7" }
]

# Ansible Groups for inventory
ansible_groups = {
  "servers" => [
    "server-1",
    "server-2",
    "server-3"
  ],
  "clients" => [
    "client-1"
  ],
  "consul_instances:children" => [
	  "servers",
	  "clients"
  ],
  "nomad_instances:children" => [
	  "servers",
	  "clients"
  ],
  "vault_instances:children" => [
	  "servers"
  ],
  "traefik_instances" => [
    "server-1"
  ],
  "all_groups:children" => [
    "servers",
    "clients"
  ],
  "all:vars" => {
    "telegraf_agent_version" => TELEGRAF_VERSION
  },
  "consul_instances:vars" => {
    "consul_version" => CONSUL_VERSION,
    "consul_client_address" => "0.0.0.0",
    "consul_iface" => "eth1"
  },
  "nomad_instances:vars" => {
    "nomad_version" => NOMAD_VERSION,
    "nomad_docker_enable" => true,
    "nomad_iface" => "eth1",
    "nomad_network_interface" => "eth1"
  },
  "vault_instances:vars" => {
    "vault_version" => VAULT_VERSION,
    "vault_address" => "0.0.0.0",
    "vault_iface" => "eth1"
  },
  "servers:vars" => {
    "consul_node_role" => "server",
    "nomad_node_role" => "both"
  },
  "clients:vars" => {
    "consul_node_role" => "client",
    "nomad_node_role" => "client"
  }
}
# Ansible Host vars for inventory
ansible_host_vars = {
  "server-1" => {
    "consul_node_role" => "bootstrap"
  }
}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # vagrant-hostmanager options
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = false

  # Always use Vagrant's insecure key
  #config.ssh.insert_key = false
  
  # Forward ssh agent to easily ssh into the different machines
  config.ssh.forward_agent = true

  # Synced Folder
  config.vm.synced_folder '.', '/vagrant', disabled: true

  # Provision servers
  servers.each do |server|
    config.vm.define server[:hostname] do |config|
      config.vm.hostname = server[:hostname]

      # Vagrant box
      config.vm.box = server[:box] ? server[:box] : DEFAULT_BOX_NAME;

      # Docker
      config.vm.provision "docker"

      config.vm.network :private_network, ip: server[:ip]

      memory = server[:ram] ? server[:ram] : DEFAULT_VM_RAM;
      cpus = server[:cpus] ? server[:cpus] : DEFAULT_VM_CPU;

      config.vm.provider :virtualbox do |vb|
        vb.customize [
          "modifyvm", :id,
          "--memory", memory.to_s,
          "--cpus", cpus.to_s,
          "--ioapic", "on",
          "--natdnshostresolver1", "on",
          "--natdnsproxy1", "on"
        ]
      end
    end
  end

  # Provision clients
  clients.each do |client|
    config.vm.define client[:hostname] do |config|
      config.vm.hostname = client[:hostname]

      # Vagrant box
      config.vm.box = client[:box] ? client[:box] : DEFAULT_BOX_NAME;

      # Docker
      config.vm.provision "docker"

      config.vm.network :private_network, ip: client[:ip]

      memory = client[:ram] ? client[:ram] : 2048;
      cpus = client[:cpus] ? client[:cpus] : 1;

      config.vm.provider :virtualbox do |vb|
        vb.customize [
          "modifyvm", :id,
          "--memory", memory.to_s,
          "--cpus", cpus.to_s,
          "--ioapic", "on",
          "--natdnshostresolver1", "on",
          "--natdnsproxy1", "on"
        ]
      end

      # Check if it's the last VM so we can provision
      if client[:hostname] == clients[-1][:hostname]

        # Install prereqs
        config.vm.provision "preinst", type: "ansible" do |ansible|
          ansible.compatibility_mode = "auto"
          ansible.config_file = "ansible/ansible.cfg"
          ansible.playbook = "ansible/preinst.yml"
          ansible.groups = ansible_groups
          ansible.host_vars = ansible_host_vars
      	  ansible.limit = "all"
        end

        # install consul
        config.vm.provision "consul", type: "ansible" do |ansible|
          ansible.compatibility_mode = "auto"
          ansible.config_file = "ansible/ansible.cfg"
          ansible.playbook = "ansible/consul.yml"
          ansible.groups = ansible_groups
          ansible.host_vars = ansible_host_vars
      	  ansible.limit = "consul_instances"
        end

        # Install prometheus node exporter
        config.vm.provision "node_exporter", type: "ansible" do |ansible|
          ansible.compatibility_mode = "auto"
          ansible.config_file = "ansible/ansible.cfg"
          ansible.playbook = "ansible/node_exporter.yml"
          ansible.groups = ansible_groups
          ansible.host_vars = ansible_host_vars
      	  ansible.limit = "all"
        end

        # Install telegraf
        config.vm.provision "telegraf", type: "ansible" do |ansible|
          ansible.compatibility_mode = "auto"
          ansible.config_file = "ansible/ansible.cfg"
          ansible.playbook = "ansible/telegraf.yml"
          ansible.groups = ansible_groups
          ansible.host_vars = ansible_host_vars
      	  ansible.limit = "all"
       end

        # install nomad
        config.vm.provision "nomad", type: "ansible" do |ansible|
          ansible.compatibility_mode = "auto"
          ansible.config_file = "ansible/ansible.cfg"
          ansible.playbook = "ansible/nomad.yml"
          ansible.groups = ansible_groups
          ansible.host_vars = ansible_host_vars
      	  ansible.limit = "nomad_instances"
          #ansible.verbose = true
        end

        # install vault
        config.vm.provision "vault", type: "ansible" do |ansible|
          ansible.compatibility_mode = "auto"
          ansible.config_file = "ansible/ansible.cfg"
          ansible.playbook = "ansible/vault.yml"
          ansible.groups = ansible_groups
          ansible.host_vars = ansible_host_vars
      	  ansible.limit = "vault_instances"
          #ansible.verbose = true
        end

        # install traefik
        config.vm.provision "traefik", type: "ansible" do |ansible|
          ansible.compatibility_mode = "auto"
          ansible.config_file = "ansible/ansible.cfg"
          ansible.playbook = "ansible/traefik.yml"
          ansible.groups = ansible_groups
          ansible.host_vars = ansible_host_vars
      	  ansible.limit = "traefik_instances"
          #ansible.verbose = true
        end

        # post-install tasks
        config.vm.provision "postinst", type: "ansible" do |ansible|
          ansible.compatibility_mode = "auto"
          ansible.config_file = "ansible/ansible.cfg"
          ansible.playbook = "ansible/postinst.yml"
          ansible.groups = ansible_groups
          ansible.host_vars = ansible_host_vars
      	  ansible.limit = "all"
          #ansible.verbose = true
        end

        # unseal vault
        config.vm.provision "unseal_vault", type: "ansible" do |ansible|
          ansible.compatibility_mode = "auto"
          ansible.config_file = "ansible/ansible.cfg"
          ansible.playbook = "ansible/unseal_vault.yml"
          ansible.groups = ansible_groups
          ansible.host_vars = ansible_host_vars
      	  ansible.limit = "vault_instances"
          #ansible.verbose = true
        end
      end
    end
  end
end
