resource "aws_iam_role" "rol_ec2_jenkins" {
  name = "Jenkins-Terraform"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_role_jenkins" {
  role       = aws_iam_role.rol_ec2_jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "profile_ec2" {
  name = "Jenkins-Terraform"
  role = aws_iam_role.rol_ec2_jenkins.name
}

resource "aws_security_group" "Jenkins-sg" {
  name        = "Jenkins-Security Group"
  description = "Open 22,443,80,8080,9000"
  vpc_id =  "vpc-0c933555d3aad9f34"

  # Define a single ingress rule to allow traffic on all specified ports
  ingress = [
    for port in [22, 80, 443, 8080, 9000, 3000] : {
      description      = "TLS from VPC"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins-sg"
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-03f4878755434977f"
  instance_type          = "t2.large"
  key_name               = "Jenkis-key"
  vpc_security_group_ids = [aws_security_group.Jenkins-sg.id]
  user_data              = templatefile("./install_jenkins.sh", {})
  iam_instance_profile   = aws_iam_instance_profile.profile_ec2.name


  tags = {
    Name = "Jenkins Server"
  }

  root_block_device {
    volume_size = 30
  }
}
