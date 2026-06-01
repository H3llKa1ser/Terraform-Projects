# GitOps Demo — Terraform + GitHub Actions + Cloudflare Pages

## One-time setup

1. Cloudflare
   - Create a free account, copy your Account ID.
   - Create an API token with:
     Account -> Cloudflare Pages -> Edit
     Zone -> DNS -> Edit  (only if using a custom domain)

2. Terraform Cloud (free remote state)
   - Create an org + workspace "gitops-demo" (API-driven execution).
   - Generate a user API token.

3. GitHub repo secrets (Settings -> Secrets -> Actions)
   - CLOUDFLARE_API_TOKEN
   - CLOUDFLARE_ACCOUNT_ID
   - TF_API_TOKEN

## The GitOps loop

1. Open a PR -> Actions runs `terraform plan` and comments the plan on the PR.
2. Review the plan, merge to main.
3. Merge triggers `terraform apply` -> Cloudflare Pages project is created/updated.
4. Cloudflare auto-builds and deploys /site from your repo.
5. Edits to site/index.html -> Cloudflare redeploys automatically.

## Run locally (optional)

cp terraform.tfvars.example terraform.tfvars
export CLOUDFLARE_API_TOKEN=xxxx
terraform init
terraform plan
terraform apply

## Tear down

terraform destroy
