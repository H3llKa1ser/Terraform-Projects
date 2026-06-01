terraform {
  cloud {
    organization = "your-tf-org"

    workspaces {
      name = "gitops-demo"
    }
  }
}
