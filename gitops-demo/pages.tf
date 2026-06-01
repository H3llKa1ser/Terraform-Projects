resource "cloudflare_pages_project" "site" {
  account_id        = var.cloudflare_account_id
  name              = var.project_name
  production_branch = var.production_branch

  source {
    type = "github"
    config {
      owner                         = var.github_owner
      repo_name                     = var.github_repo
      production_branch             = var.production_branch
      pr_comments_enabled           = true
      deployments_enabled           = true
      production_deployment_enabled = true
      preview_deployment_setting    = "all"
      preview_branch_includes       = ["*"]
    }
  }

  build_config {
    build_command   = ""
    destination_dir = "site"
    root_dir        = ""
  }

  deployment_configs {
    production {
      environment_variables = {
        ENVIRONMENT = "production"
      }
    }
    preview {
      environment_variables = {
        ENVIRONMENT = "preview"
      }
    }
  }
}
