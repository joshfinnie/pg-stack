.PHONY: init infra ansible wait deploy destroy ssh

TF_DIR=infra/terraform
ANSIBLE_DIR=ansible

init:
	cd $(TF_DIR) && terraform init

infra:
	cd $(TF_DIR) && terraform apply -auto-approve

wait:
	@echo "Waiting for SSH to become available..."
	@IP=$$(cd $(TF_DIR) && terraform output -raw droplet_ip); \
	USERNAME=$$(cd $(TF_DIR) && terraform output -raw ssh_user); \
	until bash -c "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $$USERNAME@$$IP exit"; do \
		sleep 2; \
	done
	@echo "SSH is ready!"

ansible:
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini --ask-vault-pass $(if $(TAGS),--tags $(TAGS),) pg.yaml

deploy: infra wait ansible

destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve

ssh:
	@SSH_CMD=$$(cd $(TF_DIR) && terraform output -raw ssh_command); \
	bash -c "$$SSH_CMD"
