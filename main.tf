terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# Main DynamoDB table with single-table design
resource "aws_dynamodb_table" "university_table" {
  name         = "university"
  billing_mode = "PAY_PER_REQUEST" # On-demand capacity mode
  hash_key     = "pk"
  range_key    = "sk"

  # Define the primary key attributes
  attribute {
    name = "pk"
    type = "S" # String type for partition key
  }

  attribute {
    name = "sk"
    type = "S" # String type for sort key
  }

  # Define GSI for querying students by ID
  attribute {
    name = "studentID"
    type = "S"
  }

  global_secondary_index {
    name            = "studentID-index"
    hash_key        = "studentID"
    projection_type = "ALL"
  }

  # Define GSI for querying courses by date
  attribute {
    name = "courseDate"
    type = "S"
  }

  attribute {
    name = "entityType"
    type = "S"
  }

  global_secondary_index {
    name            = "entityType-courseDate-index"
    hash_key        = "entityType"
    range_key       = "courseDate"
    projection_type = "ALL"
  }

  # TTL configuration
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  # Enable PITR (Point in Time Recovery)
  point_in_time_recovery {
    enabled = true
  }

  # Enable DynamoDB Streams for Lambda triggers
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # Enable server-side encryption with AWS managed CMK
  server_side_encryption {
    enabled = true
  }

  # Tags
  tags = {
    Name        = "university-table"
    Environment = var.environment
    Project     = "DynamoDB-Demo"
  }

  # Enable global tables - DynamoDB manages replication automatically
  dynamic "replica" {
    for_each = var.enable_global_tables ? [1] : []
    content {
      region_name = var.replica_region
    }
  }
}

# Lambda function to handle DynamoDB Streams
resource "aws_lambda_function" "dynamodb_stream_processor" {
  function_name    = "dynamodb-stream-processor"
  filename         = "lambda_function.zip"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  timeout          = 30
  memory_size      = 256
  role             = aws_iam_role.lambda_exec_role.arn
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.university_table.name
    }
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-dynamodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda to access DynamoDB
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "lambda-dynamodb-policy"
  description = "Policy for Lambda to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.university_table.arn
      },
      {
        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
        ]
        Effect   = "Allow"
        Resource = "${aws_dynamodb_table.university_table.arn}/stream/*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

# Connect Lambda to DynamoDB Stream
resource "aws_lambda_event_source_mapping" "dynamodb_trigger" {
  event_source_arn  = aws_dynamodb_table.university_table.stream_arn
  function_name     = aws_lambda_function.dynamodb_stream_processor.function_name
  starting_position = "LATEST"
  batch_size        = 100
  enabled           = true
}

# CloudWatch alarm for throttled requests
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttled_requests" {
  alarm_name          = "dynamodb-throttled-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This alarm monitors DynamoDB throttled requests"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    TableName = aws_dynamodb_table.university_table.name
  }
}

# Output the table ARN and name
output "dynamodb_table_arn" {
  value = aws_dynamodb_table.university_table.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.university_table.name
}

output "dynamodb_stream_arn" {
  value = aws_dynamodb_table.university_table.stream_arn
}
