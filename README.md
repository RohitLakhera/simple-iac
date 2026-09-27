# DevOps IaC Project: Terraform + Ansible + Jenkins + GitHub

Provision a VPC, subnets, security group and 2 Ubuntu web servers on AWS with **Terraform**,
configure them (packages + Nginx) with **Ansible**, and automate everything with a
**Jenkins** pipeline triggered by pushes to **GitHub**.

```
Developer -> git push -> GitHub -> webhook -> Jenkins
                                               |
      1. terraform init / fmt / validate / plan
      2. manual approval gate
      3. terraform apply  (state in S3)
      4. build Ansible inventory from terraform outputs
      5. ansible-playbook (common + nginx roles)
      6. curl smoke test
```

## Repo layout
```
Jenkinsfile
terraform/   versions.tf backend.tf main.tf variables.tf outputs.tf
ansible/     ansible.cfg site.yml roles/{common,nginx}
```

## Prerequisites
- AWS account + IAM user (programmatic access) with EC2/VPC/S3 permissions
- S3 bucket for Terraform state (versioning ON) -> put its name in `terraform/backend.tf`
- A Jenkins server (EC2 or Docker) with these installed: `git`, `terraform (>=1.10)`, `ansible`, `jq`, `curl`
- Jenkins plugins: Git, GitHub, Pipeline, Credentials Binding, AWS Credentials, SSH Agent (optional)

## One-time setup
1. Create an SSH key pair: `ssh-keygen -t ed25519 -f ~/.ssh/devops-iac -C jenkins`
2. Add Jenkins credentials (Manage Jenkins -> Credentials):
   | ID               | Type                          | Value                         |
   |------------------|-------------------------------|-------------------------------|
   | `aws-creds`      | AWS Credentials               | Access key + secret           |
   | `ec2-public-key` | Secret text                   | contents of `devops-iac.pub`  |
   | `ec2-ssh-key`    | SSH Username with private key | username `ubuntu` + private key |
3. Push this repo to GitHub.
4. Jenkins -> New Item -> **Pipeline** -> "Pipeline script from SCM" -> your repo URL -> branch `main`.
5. GitHub repo -> Settings -> Webhooks -> `http://<jenkins-ip>:8080/github-webhook/` (push events).
6. Run **Build with Parameters** -> `ACTION=apply`. Approve when prompted.
7. Open the URLs printed by `terraform output web_urls`.
8. Clean up: run again with `ACTION=destroy` (avoid AWS charges!).

## Before every commit
```
terraform -chdir=terraform fmt -recursive
terraform -chdir=terraform validate
```

## Run locally without Jenkins
```
cd terraform && terraform init && terraform apply -var-file=terraform.tfvars
echo "[web]" > ../ansible/inventory.ini
terraform output -json web_public_ips | jq -r '.[]' >> ../ansible/inventory.ini
cd ../ansible && ansible-playbook site.yml --private-key ~/.ssh/devops-iac
```

## Git workflow (practise this!)
`main` is protected -> create `feature/*` branch -> open Pull Request -> review -> merge -> Jenkins deploys.

## Extension ideas (resume boosters)
- Add an **ALB** + target group in Terraform (load-balance the 2 servers)
- Split into **modules** (`modules/network`, `modules/compute`) and **workspaces/tfvars** for dev/stage/prod
- Add `tflint`, `checkov` (security scan) and `ansible-lint` stages in Jenkins
- Replace the generated inventory with the **aws_ec2 dynamic inventory** plugin
- Add Prometheus + Grafana via another Ansible role; ship logs to CloudWatch
- Store secrets in **Ansible Vault** or AWS Secrets Manager
- Add Slack/email notifications in the `post` block
- Run Jenkins agents in Docker; try **GitHub Actions** as an alternative pipeline
