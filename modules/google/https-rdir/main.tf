terraform {
  required_version = ">= 0.10.0"
}

provider "google" {
  credentials = "${file("google_keys/google_service_key.json")}"
  project = "${var.project}"
}

resource "tls_private_key" "ssh" {
  count = "${var.count_vm}"
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "random_id" "server" {
  count = "${var.count_vm}"
  byte_length = 4
}

resource "google_compute_instance" "https-rdir" {
  count = "${var.count_vm}"
  machine_type = "${var.machine_type}"
  name = "https-rdir-${random_id.server.*.hex[count.index]}"
  zone = "${var.available_zones[element(var.zones, count.index)]}"
  can_ip_forward = true
  
  tags = ["redir", "startup"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "redteam-vpc"
    subnetwork = "redteam-vpc-subnet1"
    access_config {}
  }
  
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y tmux socat apache2",
      "a2enmod rewrite proxy proxy_http ssl",
      "systemctl stop apache2",
     // "tmux new -d \"socat TCP4-LISTEN:80,fork TCP4:${element(var.redirect_to, count.index)}:80\" ';' split \"socat TCP4-LISTEN:443,fork TCP4:${element(var.redirect_to, count.index)}:443\""
    ]

    connection {
      type = "ssh"
      user = "root"
      private_key = "${tls_private_key.ssh.*.private_key_pem[count.index]}"
      host = "${self.network_interface.0.access_config.0.nat_ip}"
    }
  }

  metadata_startup_script = <<SCRIPT
  sed 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config > temp.txt
  mv -f temp.txt /etc/ssh/sshd_config
  service ssh restart
  SCRIPT

  service_account {
    scopes = ["compute-rw"]
  }

  metadata = {
    sshKeys = "root:${tls_private_key.ssh.*.public_key_openssh[count.index]}"
  }

  provisioner "local-exec" {
    command = "echo \"${tls_private_key.ssh.*.private_key_pem[count.index]}\" > ./ssh_keys/http_rdir_${self.network_interface.0.access_config.0.nat_ip } && echo \"${tls_private_key.ssh.*.public_key_openssh[count.index]}\" > ./ssh_keys/http_rdir_${self.network_interface.0.access_config.0.nat_ip}.pub" 
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "rm ./ssh_keys/http_rdir_${self.network_interface.0.access_config.0.nat_ip}*"
  }
}
