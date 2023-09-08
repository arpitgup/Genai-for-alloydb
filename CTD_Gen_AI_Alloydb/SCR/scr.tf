# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GOOGLE CLOUD SOURCE REPOSITORY
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "4.15.0"
    }
  }
}

# Make Cloud Source Repo
resource "google_sourcerepo_repository" "repo" {
  name = var.repository_name
  project = var.project_id
}

# Clone Existing Repo and Push to Cloud Source Repo
resource "time_sleep" "sleep_y" {
  create_duration = "30s"
  depends_on = [
    google_sourcerepo_repository.repo
  ]
}

resource "null_resource" "git_clone" {

 # Clone local repo (# cp ${path.module}/files/* . on line 37 and touch test.txt for testing)
 provisioner "local-exec" {
   command = <<EOF
gcloud source repos clone ${var.repository_name} --project="${var.project_id}"
cp -r ./SCR/files/GenAI-for-Alloydb/* ${var.repository_name}
cd ${var.repository_name}
git config --global user.email \"you@example.com\" 
git config --global user.name \"Your Name\" 
git add -A .
git commit -m "Source code for webapp moved to this repository"
git push origin master
cd ..
rm -rf example-repo
EOF
 }
depends_on = [
 time_sleep.sleep_y
]

}

