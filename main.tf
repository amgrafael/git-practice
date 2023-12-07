terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-west-1"
  access_key = "AKIASEGDPBDJZ37ACKQD"
  secret_key = "XAXDIYYHghC2MreikE83Xy3yJs9SBqhGtmJv/vGr"
}

#provider "aws" {
#  version = "~> 5.0"
#  region  = "us-west-1"
#  profile = "default"
#}


resource "aws_instance" "example" {
  ami           = "ami-0e534e4c6bae7faf7"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleInstance"
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "Policy for Lambda function to stop EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "ec2:StopInstances",
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_lambda_function" "stop_instance_lambda" {
  function_name = "stop_instance_lambda"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.8"

  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

resource "aws_cloudwatch_event_rule" "schedule_event_rule" {
  name                = "stop_instance_daily"
  description         = "Schedule Lambda function to stop EC2 instance daily"
  schedule_expression = "cron(0 13 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "lambda_event_target" {
  rule      = aws_cloudwatch_event_rule.schedule_event_rule.name
  target_id = "StopInstanceEventTarget"
  arn       = aws_lambda_function.stop_instance_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_stop_instance" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_instance_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule_event_rule.arn
}
