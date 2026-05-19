terraform {
    required_providers {
    virtualbox = {
    source  = "terra-farm/virtualbox"
        version = "0.2.2-alpha.1"
        }
    }
}

# Configuramos el proveedor de VirtualBox
provider "virtualbox" {
    # Dejamos esto vacío por ahora
}

# Definimos la máquina virtual de Ubuntu
resource "virtualbox_vm" "nodo_practica" {
    count     = 1
    name      = "ubuntu-servidor-ansible"
    image     = "https://app.vagrantup.com/ubuntu/boxes/focal64/versions/20230515.0.0/providers/virtualbox.box"
    cpus      = 2
    memory    = "2048 mib"

    # Tarjeta NAT para que tenga internet y descargue paquetes
    network_adapter {
        type           = "nat"
    }

    # Tarjeta Host-only para que podamos entrar por SSH desde nuestro equipo
    network_adapter {
    type           = "hostonly"
    host_interface = "VirtualBox Host-Only Ethernet Adapter"
    }
}