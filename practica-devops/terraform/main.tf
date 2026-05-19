terraform {
  required_providers {
    # Usamos el provider 'null' para poder ejecutar comandos locales de Bash
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
  }
}

# --- DECLARACIÓN DE VARIABLES ---
# Estos valores se inyectan desde el archivo terraform.tfvars
variable "vm_name" {
  type        = string
}

variable "ova_path" {
  type        = string
}

# Puertos por defecto (se pueden sobreescribir si están ocupados)
variable "ssh_port" {
  type        = string
  default     = "2222"
}

variable "apache_port" {
  type        = string
  default     = "8080"
}

variable "prometheus_port" {
  type        = string
  default     = "9090"
}

variable "grafana_port" {
  type        = string
  default     = "3000"
}


# --- RECURSO DE DESPLIEGUE ---
resource "null_resource" "virtualbox_vm" {
  
  # 1. Condicional: Solo importa la OVA de 3GB si la máquina no existe previamente
  provisioner "local-exec" {
    command = <<EOT
      if ! VBoxManage showvminfo "${var.vm_name}" > /dev/null 2>&1; then
        echo "Importando OVA desde ${var.ova_path}..."
        VBoxManage import "${var.ova_path}" --vsys 0 --vmname "${var.vm_name}"
      else
        echo "La máquina '${var.vm_name}' ya existe, omitiendo importación."
      fi
    EOT
  }

  # 2. Configura el adaptador en modo NAT, limpia reglas y abre los puertos
  provisioner "local-exec" {
    command = <<EOT
      VBoxManage modifyvm "${var.vm_name}" --nic1 nat
      
      # Limpieza preventiva de reglas previas para evitar conflictos
      VBoxManage modifyvm "${var.vm_name}" --natpf1 delete "ssh" 2>/dev/null || true
      VBoxManage modifyvm "${var.vm_name}" --natpf1 delete "apache" 2>/dev/null || true
      VBoxManage modifyvm "${var.vm_name}" --natpf1 delete "prometheus" 2>/dev/null || true
      VBoxManage modifyvm "${var.vm_name}" --natpf1 delete "grafana" 2>/dev/null || true

      # Mapeo final usando las variables (Host_Port -> Guest_Port)
      VBoxManage modifyvm "${var.vm_name}" --natpf1 "ssh,tcp,,${var.ssh_port},,22"
      VBoxManage modifyvm "${var.vm_name}" --natpf1 "apache,tcp,,${var.apache_port},,80"
      VBoxManage modifyvm "${var.vm_name}" --natpf1 "prometheus,tcp,,${var.prometheus_port},,9090"
      VBoxManage modifyvm "${var.vm_name}" --natpf1 "grafana,tcp,,${var.grafana_port},,3000"
    EOT
  }

  # 3. Arranca la máquina. El modo 'separate' lanza la interfaz sin bloquear la terminal
  provisioner "local-exec" {
    command = "VBoxManage startvm \"${var.vm_name}\" --type separate"
  }

  # 4. Destrucción (terraform destroy): Apagado forzoso y borrado total del disco virtual
  provisioner "local-exec" {
    when    = destroy
    command = "VBoxManage controlvm \"${self.triggers.vm_name}\" poweroff 2>/dev/null || true && VBoxManage unregistervm \"${self.triggers.vm_name}\" --delete"
  }

  # Guarda el nombre de la VM en el estado de Terraform para que el destroy sepa qué borrar
  triggers = {
    vm_name = var.vm_name
  }
}