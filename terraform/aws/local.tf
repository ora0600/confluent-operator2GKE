resource "null_resource" "setup-cluster" {
  depends_on = [
    aws_eks_cluster.cp60
  ]
  triggers = {
    id = aws_eks_cluster.cp60.id
    // Re-run script on deployment script changes
    script = sha1(file("00_setup_EKS.sh"))
  }

  provisioner "local-exec" {
    command = "./00_setup_EKS.sh ${var.aws_region} ${var.cluster-name}"
  }
}

resource "null_resource" "setup-messaging" {
  depends_on = [
    null_resource.setup-cluster
  ]

  provisioner "local-exec" {
    command = "../01_installConfluentPlatform.sh ${var.aws_region} ${var.cprovider}"
  }
}
