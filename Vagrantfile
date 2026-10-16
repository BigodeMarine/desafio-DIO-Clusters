# Quatro VMs Ubuntu no VirtualBox, com rede privada e provisionamento automático.
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.boot_timeout = 600

  machines = {
    "master" => "192.168.56.10",
    "node01" => "192.168.56.11",
    "node02" => "192.168.56.12",
    "node03" => "192.168.56.13"
  }

  machines.each do |name, ip|
    config.vm.define name, primary: (name == "master") do |vm|
      vm.vm.hostname = name
      vm.vm.network "private_network", ip: ip

      vm.vm.provider "virtualbox" do |vb|
        vb.memory = 1024
        vb.cpus = 1
      end

      # Instalação comum executada antes da configuração do papel de cada nó.
      vm.vm.provision "shell", path: "scripts/install-docker.sh"
      vm.vm.provision "shell", path: "scripts/configure-swarm.sh",
        args: [name, ip, machines.fetch("master")]
    end
  end
end
