#cloud-config
users:
  - name: ${username}
    groups: sudo,docker
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${ssh_public_key}

ssh_pwauth: false
disable_root: true

package_update: true
package_upgrade: true

packages:
  - fail2ban
  - ufw
  - docker.io
  - docker-compose-plugin

runcmd:
  # Firewall
  - ufw allow OpenSSH
  - ufw --force enable

  # Harden SSH
  - sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
  - sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
  - systemctl restart ssh

  # Docker
  - systemctl enable docker
  - systemctl start docker
