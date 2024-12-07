locals {
  name_prefix = "sean"
}

## DynamoDB
resource "aws_dynamodb_table" "bookinventory" {
  name           = "${local.name_prefix}-bookinventory"
  hash_key       = "ISBN"
  range_key      = "Genre"

  billing_mode   = "PAY_PER_REQUEST"

  attribute {
    name = "ISBN"
    type = "S"
  }

  attribute {
    name = "Genre"
    type = "S"
  }

}

## IAM Role and Permissions
resource "aws_iam_role" "role_dynamodb" {
  name = "${local.name_prefix}-role-dynamodb"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "policy_dynamodb" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:ListTables"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["dynamodb:Scan"]
    resources = [aws_dynamodb_table.bookinventory.arn]
  }
}

resource "aws_iam_policy" "policy_dynamodb" {
  name = "${local.name_prefix}-policy-dynamodb"
  policy = data.aws_iam_policy_document.policy_dynamodb.json
}

resource "aws_iam_role_policy_attachment" "attach_dynamodb" {
  role       = aws_iam_role.role_dynamodb.name
  policy_arn = aws_iam_policy.policy_dynamodb.arn
}

resource "aws_iam_instance_profile" "profile_dynamodb" {
  name = "${local.name_prefix}-profile-dynamodb"
  role = aws_iam_role.role_dynamodb.name
}

## EC2 Instance
resource "aws_instance" "dynamodb_reader" {
  ami                    = "ami-04c913012f8977029"
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.dynamodb_reader.id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.profile_dynamodb.id

  tags = {
    Name = "${local.name_prefix}-dynamodb-reader"
  }
}

resource "aws_security_group" "dynamodb_reader" {
  name        = "${local.name_prefix}-sg"
  description = "Allow SSH inbound"
  vpc_id      = data.aws_vpc.selected.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.dynamodb_reader.id
  cidr_ipv4         = "0.0.0.0/0"  
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_https_traffic_ipv4" {
  security_group_id = aws_security_group.dynamodb_reader.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_https_traffic_ipv6" {
  security_group_id = aws_security_group.dynamodb_reader.id
  cidr_ipv6         = "::/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
