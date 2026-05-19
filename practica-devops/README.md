# 🚀 Despliegue DevOps automatizado (RA5_1)

![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-2.4+-D24939?logo=jenkins&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-2.14+-EE0000?logo=ansible&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-24+-2496ED?logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-E95420?logo=ubuntu&logoColor=white)
![Apache](https://img.shields.io/badge/Apache2-2.4-D22128?logo=apache&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-2.31-E6522C?logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-10+-F46800?logo=grafana&logoColor=white)

Proyecto completo de integración y despliegue continuo (CI/CD) diseñado para provisionar y configurar una máquina virtual de forma 100% desatendida. Orquestado desde **Jenkins** en WSL, aprovisionado con **Terraform** en Windows (VirtualBox), y configurado mediante contenedores Docker efímeros ejecutando **Ansible**.

---

## 🏗️ Arquitectura de red y sistema

El despliegue cruza la frontera entre el subsistema de Linux (WSL) y el anfitrión Windows sin necesidad de scripts intermediarios o wrappers, utilizando comandos nativos e IPs locales.

```text
💻 WSL (Ubuntu/Kali)
├── 👷 Jenkins (Nativo, .war)   -> Orquestador del pipeline (:8090)
├── 🏗️ Terraform (Nativo)      -> Aprovisionamiento directo al disco C:
└── 🐳 Docker                   -> Levanta el contenedor efímero de Ansible

🪟 Windows host (IP: 192.168.x.x)
└── 📦 VirtualBox               -> Recibe la orden de Terraform e importa la VM

🌐 Red NAT de VirtualBox (Port Forwarding Dinámico)
├── Apache2    :80   -> localhost:8080
├── Prometheus :9090 -> localhost:9090
└── Grafana    :3000 -> localhost:3000
```

---

## 📋 Requisitos previos

1. **Windows 11 con WSL2** y Docker Desktop activado con integración WSL.
2. **VirtualBox** instalado en Windows.
3. **Imagen OVA** de Ubuntu 22.04 con *VirtualBox Guest Additions* instaladas (recomendado: [OsBoxes.org](https://www.osboxes.org/ubuntu/)).

---

## 🛠️ Preparación del entorno (Paso 0)

Si tu entorno WSL está limpio, el proyecto incluye un script de preparación inicial. Este script se encarga de automatizar la instalación de todas las dependencias necesarias en la máquina anfitriona (Java, Terraform, Docker) y descarga el ejecutable de Jenkins.

Ejecútalo una sola vez antes de empezar:

```bash
chmod +x preparar_entorno.sh
./preparar_entorno.sh
```

---

## ⚙️ Configuración del proyecto

El proyecto está diseñado para no hardcodear datos personales en el código. Antes de ejecutar el pipeline, debes definir tu entorno local:

### 1. Variables de Terraform (`terraform.tfvars`)

Crea un archivo llamado `terraform.tfvars` en el directorio `/terraform` indicando la ruta absoluta de Windows hacia tu archivo `.ova` (usa barras normales `/`):

```hcl
vm_name  = "ubuntu-servidor-ansible"
ova_path = "C:/Users/[USUARIO]/Downloads/Ubuntu-22.04-64bit-VB.ova"
```

### 2. Inventario de Ansible (`inventory.ini`)

Para evitar el enrutamiento complejo entre WSL y Windows, Ansible ataca directamente a la IP de tu adaptador de red. Abre `ansible/inventory.ini` y pon la IP local de tu máquina Windows (la que te da el comando `ipconfig`):

```ini
[web]
target ansible_host=[IP_LOCAL] ansible_port=2222 ansible_user=osboxes ansible_password=osboxes.org ansible_become_password=osboxes.org ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

---

## 🚀 Despliegue: El Jenkinsfile

Arranca Jenkins en tu terminal de WSL:

```bash
java -jar ~/jenkins.war --httpPort=8090
```

Accede a `http://localhost:8090`, crea un Job de tipo Pipeline apuntando a este repositorio y haz clic en **Construir Ahora**. El proceso consta de 5 fases completamente autónomas:

| Fase | Tarea Principal | Detalles Técnicos |
| --- | --- | --- |
| **1. Init** | Inicialización | Descarga de proveedores de HashiCorp para entorno `null_resource`. |
| **2. Apply** | Aprovisionamiento | Importación de OVA, mapeo de puertos dinámicos (`natpf1`) y arranque `separate` para evitar cuelgues *headless*. |
| **3. Config SSH** | Configuracion silenciosa | Bypassea la falta de SSH en imágenes de escritorio usando `VBoxManage guestcontrol` para matar procesos `apt-daily` e instalar `openssh-server` en modo fantasma. |
| **4. Ansible** | Gestión de Configuración | Construye imagen Alpine Docker, inyecta `sshpass` y ejecuta el Playbook de forma idempotente. Instala Apache, añade repositorios GPG de Grafana, descarga Prometheus y levanta los servicios. |
| **5. Test** | Verificación HTTP | Ejecuta peticiones `curl` a los puertos mapeados buscando códigos HTTP 200 (OK) y 302 (Found). |

---

## 📊 Verificación de Servicios

Una vez finalizado el Pipeline (estado `SUCCESS`), accede desde tu navegador web anfitrión:

* **Página de aterrizaje (Apache):** `http://localhost:8080`
* **Métricas en crudo (Prometheus):** `http://localhost:9090`
* **Dashboards (Grafana):** `http://localhost:3000` *(User/Pass inicial: admin/admin)*. El Datasource de Prometheus y el Dashboard de "Node Exporter Full" ya estarán auto-configurados.

---

## 🧹 Destrucción de la Infraestructura

Mantener entornos limpios es clave. Para eliminar la máquina virtual de VirtualBox y liberar espacio en disco, simplemente ejecuta:

```bash
cd terraform
terraform destroy -auto-approve
```

*(Terraform utilizará triggers para leer el nombre dinámico de la VM, la apagará de forma forzada si está encendida y la desregistrará del hipervisor)*.