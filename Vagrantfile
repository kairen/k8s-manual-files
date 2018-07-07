Vagrant.require_version ">= 1.7.0"

def set_vbox(vb, config)
  vb.gui = false
  vb.memory = 2048
  vb.cpus = 1
end

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox"
  config.vm.box = "bento/ubuntu-16.04"

  private_count = 11
  (1..6).each do |mid|
    name = (mid <= 3) ? "k8s-m" : "k8s-n"
    id = (mid <= 3) ? mid : mid - 3
    config.vm.define "#{name}#{id}" do |n|
      n.vm.hostname = "#{name}#{id}"
      ip_addr = "192.16.35.#{private_count}"
      n.vm.network :private_network, ip: "#{ip_addr}", auto_config: true
      n.vm.provider :virtualbox do |vb, override|
        vb.name = "#{n.vm.hostname}"
        set_vbox(vb, override)
      end
      private_count += 1
    end
  end
  config.vm.provision "shell", path: "./hack/setup-vm.sh"
end
