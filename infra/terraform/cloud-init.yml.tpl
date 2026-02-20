#cloud-config
users:
  - name: ${username}
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${ssh_public_key}

ssh_pwauth: false
disable_root: true
