variable "application-name" {
  type = string
  default = "pipeline-template"
}

module "cicd-pipeline-master-branch" {
  source = "./cicd-pipeline"

  application-name = var.application-name
  branch = "master"
  repository-name = aws_codecommit_repository.codecommit-repository.repository_name
}

data "template_file" "master-build-succeeded-event-rulefile" {
  template = file("pipeline-event-rule.tpl")

  vars = {
    codepipeline-name = module.cicd-pipeline-master-branch.codepipeline-name
    state = "SUCCEEDED"
  }
}

module "cicd-pipeline-master-build-succeeded-notification" {
  source = "./cicd-notification"

  name = "${var.application-name}-notification-build-success-master"

  subject = "New Build Available"
  message =<<EOT
  Build Succeeded, please download latest artifact here: https://s3.console.aws.amazon.com/s3/buckets/${module.cicd-pipeline-master-branch.cicd-artifact-bucket-name}/?region=us-east-1
EOT

  rule = data.template_file.master-build-succeeded-event-rulefile.rendered
  slack-url = var.slack-url-succeeded
}

data "template_file" "master-build-failed-event-rulefile" {
  template = file("pipeline-event-rule.tpl")

  vars = {
    codepipeline-name = module.cicd-pipeline-master-branch.codepipeline-name
    state = "FAILED"
  }
}

module "cicd-pipeline-master-build-failed-notification" {
  source = "./cicd-notification"

  name = "${var.application-name}-notification-build-fail-master"
  slack-url = var.slack-url-failed

  message =<<EOT
  Build Failed, please check the build output here:
https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${module.cicd-pipeline-master-branch.codepipeline-name}/view?region=us-east-1#
EOT

  subject = "Build Failed"

  rule = data.template_file.master-build-failed-event-rulefile.rendered
}

module "cicd-pipeline-dev-branch" {
  source = "./cicd-pipeline"

  application-name = var.application-name
  branch = "dev"
  repository-name = aws_codecommit_repository.codecommit-repository.repository_name
}

data "template_file" "dev-build-succeeded-event-rulefile" {
  template = file("pipeline-event-rule.tpl")

  vars = {
    codepipeline-name = module.cicd-pipeline-dev-branch.codepipeline-name
    state = "SUCCEEDED"
  }
}

module "cicd-pipeline-dev-build-succeeded-notification" {
  source = "./cicd-notification"

  name = "${var.application-name}-notification-build-success-dev"
  slack-url = var.slack-url-succeeded

  message =<<EOT
  Build Succeeded, please download latest artifact here: https://s3.console.aws.amazon.com/s3/buckets/${module.cicd-pipeline-dev-branch.cicd-artifact-bucket-name}/?region=us-east-1
EOT
  subject = "New Build Available"

  rule = data.template_file.dev-build-succeeded-event-rulefile.rendered
}

data "template_file" "dev-build-failed-event-rulefile" {
  template = file("pipeline-event-rule.tpl")

  vars = {
    codepipeline-name = module.cicd-pipeline-dev-branch.codepipeline-name
    state = "FAILED"
  }
}

module "cicd-pipeline-dev-build-failed-notification" {
  source = "./cicd-notification"

  name = "${var.application-name}-notification-build-fail-dev"
  slack-url = var.slack-url-failed

  message =<<EOT
  Build Failed, please check the build output here: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${module.cicd-pipeline-dev-branch.codepipeline-name}/view?region=us-east-1#
EOT

  subject = "Build Failed"

  rule = data.template_file.dev-build-failed-event-rulefile.rendered
}
