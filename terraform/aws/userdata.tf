###########################################
######## Confluent 5.3 Dev Instance ##########
###########################################

data "template_file" "setup-eks" {
  template = file("00_setup_EKS.sh")

}
