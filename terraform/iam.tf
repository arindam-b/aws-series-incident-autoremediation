# Creation of role
resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    app-name = var.app_name,
    environment = var.env
  }
}

# Creation of policy
resource "aws_iam_policy" "policy" {
  name        = var.policy_name
  description = var.policy_description

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "cloudwatch:DescribeAlarms"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "ssm:SendCommand"
            ],
            "Resource": [                
                "*"
            ]
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.bucket_name}/*"
        }
    ]
}
EOF

  tags = {
    environment = "dev"
    app = "autoremediation"
  }
}

# Attach custom policy to a role
resource "aws_iam_role_policy_attachment" "customer-managed-policy-role-attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.policy.arn
}


# AWS Managed policy attached to a role 
resource "aws_iam_role_policy_attachment" "aws_iam_role_aws_managed_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}


