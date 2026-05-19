#!/bin/bash
echo " Configurando el entorno WSL2..."

# Actualizar repositorios e instalar Java y utilidades
sudo apt-get update
sudo apt-get install -y openjdk-21-jdk sshpass wget gnupg software-properties-common

# Instalar Terraform oficialmente
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -y -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform

# Descargar Jenkins de forma limpia
echo " Descargando Jenkins..."
wget -nc https://get.jenkins.io/war-stable/latest/jenkins.war -P ~/

echo " Entorno listo. Arranca Jenkins ejecutando: java -jar ~/jenkins.war --httpPort=8090"