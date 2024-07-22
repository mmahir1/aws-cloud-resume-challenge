resource "aws_lambda_function"  "myfunction" {
    filename = data.archive_file.zip.output_path
    source_code_hash = data.archive_file.zip.output_base64sha256
    function_name = "myfunction"
    role =  aws_iam_role.iam_for_lambda.arn
    handler = "myfunction.handler"
    runtime = "python3.12"
}

resource "aws_iam_role" "server_role" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_resume-project" {
    name = "aws_iam_policy_for_terraform_resume_challenge_policy"
    path = "/"
    description = "AWS IAM policy to manage resume challenge"

        policy = jsondecode(
            {
                "version" : "2012-10-17"
                "statement" : [
                    {
                        "Action" : [
                            "logs:CreateLogGroup",
                            "logs:CreateLogStream",
                            "logs:PutLogEvents"
                        ],
                        "Resource" : "arn:aws:logs:*:*:*",
                        "Effect" : "Allow"
                    },
                    {
                        "Effect" : "Allow",
                        "Action" : [
                            "dynamodb:UpdateItem",
                            "dynamodb:GetItem"
                        ],
                        "Resource" : "arn:aws:dynamodb:*:*:table/resume-challenge"
                    },
                ]
            }

        )
  
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.iam_policy_for_resume-project.arn
}

data archive_file "zip" {
    type = "zip"
    source_dir = "${path.module}/lambda/"
    output_path = "${path.module}/packedlambda.zip"
}

resource "aws_lambda_function_url" "myurl" {
  function_name      = aws_lambda_function.myfunction.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["https://resume.musayyib.com"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}