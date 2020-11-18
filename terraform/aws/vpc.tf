#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "cp60" {
  cidr_block = "10.0.0.0/16"

  tags = "${
    map(
      "Name", "terraform-eks-cp60-node",
      "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "cp60" {
  count = var.az_count

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.cp60.id}"
  map_public_ip_on_launch = true

  tags = "${
    map(
      "Name", "terraform-eks-cp60-node",
      "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "cp60" {
  vpc_id = "${aws_vpc.cp60.id}"

  tags = {
    Name = "terraform-eks-cp60"
  }
}

resource "aws_route_table" "cp60" {
  vpc_id = "${aws_vpc.cp60.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.cp60.id}"
  }
}

resource "aws_route_table_association" "cp60" {
  count = var.az_count

  subnet_id      = "${aws_subnet.cp60.*.id[count.index]}"
  route_table_id = "${aws_route_table.cp60.id}"
}
