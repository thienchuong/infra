module "secrets_manager" {
  source = "terraform-aws-modules/secrets-manager/aws"

  # Secret
  name_prefix             = "secret-rotated-example"
  description             = "Rotated example Secrets Manager secret"
  recovery_window_in_days = 7

  # Policy
  create_policy       = true
  block_public_policy = true
  policy_statements = {
    lambda = {
      sid = "LambdaReadWrite"
      principals = [{
        type        = "AWS"
        identifiers = [module.lambda.lambda_role_arn]
      }]
      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:UpdateSecretVersionStage",
      ]
      resources = ["*"]
    }
  }

  # Version
  ignore_secret_changes = true
  secret_string = jsonencode({
    engine   = "mariadb",
    host     = "mydb.cluster-123456789012.us-east-1.rds.amazonaws.com",
    username = "ToninoLamborghini",
    password = "ThisIsMySuperSecretString12356!"
    dbname   = "mydb",
    port     = 3306
  })

  # Rotation
  enable_rotation     = true
  rotation_lambda_arn = module.lambda.lambda_function_arn
  rotation_rules = {
    # This should be more sensible in production
    schedule_expression = "rate(6 hours)"
  }

  tags = local.tags
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = [module.secrets_manager.secret_arn]
  }

  statement {
    actions   = ["secretsmanager:GetRandomPassword"]
    resources = ["*"]
  }

  statement {
    actions   = ["secretsmanager:GetRandomPassword"]
    resources = ["*"]
  }
}

module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 6.0"

  function_name = "lambda-func"
  description   = "lambda function rotate secrets in Secret Manager"

  handler     = "function.lambda_handler"
  runtime     = "python3.10"
  timeout     = 60
  memory_size = 512
  source_path = "${path.module}/function.py"

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.this.json

  publish = true
  allowed_triggers = {
    secrets = {
      principal = "secretsmanager.amazonaws.com"
    }
  }

  cloudwatch_logs_retention_in_days = 7

  tags = local.tags
}
