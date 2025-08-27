provider "aws" {
  region = var.aws_region
}

# Data source para obter o ID da conta AWS atual
data "aws_caller_identity" "current" {}

# 1. Compactar o código da Lambda em um arquivo zip
# Isso garante que o código e suas dependências (node_modules) sejam incluídos.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}"
  output_path = "${path.module}/lambda.zip"
  # Exclui arquivos desnecessários do zip para mantê-lo menor
  excludes = [
    "main.tf",
    "variables.tf",
    "terraform.tfstate",
    ".terraform",
    "lambda.zip"
  ]
}

# 2. IAM Role e Policy para a Lambda
# A Lambda precisa de permissão para ser executada e para escrever logs no CloudWatch.
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 3. Recurso da Função Lambda
resource "aws_lambda_function" "webhook_handler" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      # Passa o endpoint como variável de ambiente para a função
      TARGET_ENDPOINT_URL = var.target_endpoint_url
    }
  }

  timeout = 10 # Segundos
}

# 4. API Gateway para expor a Lambda publicamente
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.function_name}-api"
  description = "API para receber webhooks do Docker Hub"
}

resource "aws_api_gateway_resource" "webhook_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "webhook" # O caminho será /webhook
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.webhook_resource.id
  http_method   = "POST" # Docker Hub envia via POST
  authorization = "NONE"
}

# 5. Integração entre o API Gateway e a Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.webhook_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY" # Passa o request inteiro para a Lambda
  uri                     = aws_lambda_function.webhook_handler.invoke_arn
}

# 6. Permissão para o API Gateway invocar a Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayToInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webhook_handler.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.post_method.http_method}${aws_api_gateway_resource.webhook_resource.path}"
}

# 7. Deploy da API para torná-la acessível
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  # Garante que um novo deploy seja feito sempre que a API mudar
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.webhook_resource.id,
      aws_api_gateway_method.post_method.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"
}

# 8. Output com a URL final do webhook
output "webhook_url" {
  description = "URL para configurar no webhook do Docker Hub."
  value       = "${aws_api_gateway_stage.api_stage.invoke_url}/${aws_api_gateway_resource.webhook_resource.path_part}"
}