
# Desafio DevSecOps - Pipeline de Automação

Este repositório contém a implementação completa de uma pipeline DevSecOps para automatizar o build, análise de segurança, publicação e deploy de uma aplicação em um cluster Kubernetes, incluindo recursos de infraestrutura como código com Terraform na AWS.

## 📋 Sumário

- [Visão Geral](#visão-gera)
- [Pré-requisitos](#pré-requisitos)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Configuração e Implementação](#configuração-e-implementação)
- [Pipeline CI/CD](#pipeline-cicd)
- [Análise de Segurança](#análise-de-segurança)
- [Configuração Ingress](#Configuração Ingress)
- [Lambda Function com Terraform](#lambda-function-com-terraform)
- [Execução e Testes](#execução-e-testes)
- [Boas Práticas Implementadas](#boas-práticas-implementadas)
- [Monitoramento e Logs](#monitoramento-e-logs)
- [Considerações de Segurança](#considerações-de-segurança)

## 🎯 Visão Geral

Este projeto implementa uma pipeline completa de DevSecOps que:
1. Realiza análise estática e dinâmica de código
2. Constrói e publica imagens Docker no Docker Hub
3. Faz deploy automático em cluster Kubernetes com Ingress Controller
4. Inclui função Lambda na AWS (via Terraform) para notificação pós-deploy

## ⚙️ Pré-requisitos

Antes de executar este projeto, certifique-se de ter:

- **Conta no Docker Hub** com repositório criado
- **Cluster Kubernetes** configurado (local ou cloud)
- **Ingress Controller** instalado no cluster (ex: Nginx Ingress)
- **Conta AWS** com credenciais configuradas
- **Terraform** instalado (versão 1.0+)
- **GitHub Actions** (ferramenta de CI/CD escolhida)

Repositorios onde consta o projeto:
GitHub: https://github.com/Cesarforfun/Desafio_Winnin
DockerHub : cesar4fun/desafio_winnin

## 📁 Estrutura do Projeto
├───.github
│   └───workflows
├───config
├───controllers
├───kubernetes
├───lambda-trigger
│   └───node_modules
├───middleware
├───models
├───node_modules
├───routes
└───utils
```

## 🔧 Configuração e Implementação

Repositório Git Hub:  https://github.com/Cesarforfun/Desafio_Winnin
Repositório Docker Hub : cesar4fun/desafio_winnin

### 1. Configuração do Ambiente

**Variáveis de Ambiente Necessárias:**
```bash
export DOCKER_USERNAME="seu_usuario_dockerhub"
export DOCKER_PASSWORD="sua_senha_dockerhub"
export DOCKER_REPOSITORY="seu_repositorio/nome-da-app"
export AWS_ACCESS_KEY_ID="sua_access_key"
export AWS_SECRET_ACCESS_KEY="sua_secret_key"
```
Obs: Como não tinha uma conta AWS para validar eu não preenchi as variaveis reais aqui

### 2. Configuração do Docker Hub

Nas configurações do docker hub ao configurar o repositorio, em Image security insight settings, foi habilitado o static Scanning ( como minha conta e gratis, não pude habilitar esta opção )

### 3. Configuração Ingress

Certifique-se de que seu cluster está rodando e acessível:


```

## 🔄 Pipeline CI/CD

A pipeline implementada segue os seguintes estágios:

### Estágio 1
- Ao realizar a git push para o seu repositório no GitHub

### Estágio 2
- A pipeline do GitHub Actions (ci-cd-pipeline.yml) é acionada

### Estágio 3
- A pipeline constrói a imagem Docker e a publica no Docker Hub com docker push.

### Estágio 4
- Os testes são realizados na pipeline

### Estágio 5
- Assim que o push é concluído, o Docker Hub envia uma notificação POST para a URL do seu API Gateway.

### Estágio 6
- O API Gateway recebe a notificação e aciona sua função Lambda.

### Estágio 7
- A função Lambda lê a variável de ambiente TARGET_ENDPOINT_URL (que você configurou no Terraform) e faz a chamada GET para o seu endpoint.

### Estágio 8: Pós-Deploy
- Execução da Lambda function para chamada GET
- Testes de smoke pós-deploy
- Notificações de status

## 🔍 Análise de Segurança

### Análise Estática (SAST)
- **Snyk security scan: Para análise de qualidade e segurança do código, rodando no kubernets

### Análise Dinâmica (DAST)
- **OWASP ZAP**: Para teste de segurança da aplicação em runtime, rodando no kubernets


## 🚀 Lambda Function com Terraform


Os arquivo de configuração para a função Lambda es na pasta Lambda-trigger:
index.json -> Código da Função Lambda
main.tf -> Arquivo Terraform
variables.tf -> Variáveis do Terraform
package.json -> Dependências da Lambda

### Implementação do Módulo Terraform

O módulo Terraform cria:
- Função Lambda para fazer chamadas GET
- Role IAM com permissões apropriadas
- Trigger a partir de eventos do Docker Hub ( via webhook )

### Código da Lambda

# lambda-trigger/index.json

import fetch from 'node-fetch';

export const handler = async (event) => {
    // Pega a URL do endpoint a ser chamado a partir das variáveis de ambiente da Lambda
    const targetEndpoint = process.env.TARGET_ENDPOINT_URL;

    if (!targetEndpoint) {
        console.error("Erro: A variável de ambiente 'TARGET_ENDPOINT_URL' não foi definida.");
        return {
            statusCode: 500,
            body: JSON.stringify({ message: "Variável de ambiente TARGET_ENDPOINT_URL não configurada." }),
        };
    }

    console.log(`Recebido gatilho do DockerHub. Fazendo chamada GET para: ${targetEndpoint}`);
    // Opcional: Você pode inspecionar o corpo do webhook do Docker Hub se precisar
    // console.log("Payload do Docker Hub:", JSON.stringify(event, null, 2));


    try {
        const response = await fetch(targetEndpoint);
        const data = await response.text(); // ou response.json() se o endpoint retornar JSON

        console.log(`Chamada para ${targetEndpoint} bem-sucedida. Status: ${response.status}`);
        console.log("Resposta:", data);

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: "Chamada GET realizada com sucesso!",
                target: targetEndpoint,
                status: response.status
            }),
        };
    } catch (error) {
        console.error(`Erro ao chamar o endpoint ${targetEndpoint}:`, error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: `Falha ao fazer a chamada GET: ${error.message}` }),
        };
    }
};
```

### Configuração do Terraform

```hcl
# lambda-trigger/main.tf
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
```

## 🧪 Execução e Testes

### Execução da Pipeline

1. **Localmente (para testes)**:
```bash
deploy-local.sh
```

2. **Via GitHub Actions**:
- Configure as credenciais necessárias
- Execute o pipeline a partir do repositório

### Testes Pós-Deploy

```bash
# Verificar status do deploy
kubectl get all -n app-namespace

# Testar o endpoint
curl http://seu-ingress-endpoint/health

# Verificar logs
kubectl logs -l app=my-app -n app-namespace
```

## ✅ Boas Práticas Implementadas

### Segurança
- Scanning de vulnerabilidades em múltiplas camadas
- Uso de secrets management para credenciais
- Imagens base minimalistas e seguras
- Políticas de segurança de pods no Kubernetes

### Infraestrutura como Código
- Versionamento de toda a infraestrutura
- Módulos Terraform reutilizáveis
- Variabilização de configurações

### CI/CD
- Pipeline como código
- Estágios paralelos quando possível
- Fail rápido com validações early-stage
- Rollback automático em caso de falha

### Kubernetes
- Namespace isolation
- Resource limits e requests
- Readiness e liveness probes
- Estratégia de rollout apropriada

## 🔒 Considerações de Segurança

### Implementadas
- Scanning de dependências em todo o pipeline
- Análise estática e dinâmica de código
- Imagens Docker assinadas e validadas
- Segregacao de duties com diferentes credenciais

---

## 📞 Suporte

Para dúvidas ou problemas com esta implementação, consulte a documentação oficial das ferramentas ou abra uma issue neste repositório.

## 📝 Licença

Este projeto é destinado para fins educacionais como parte do desafio DevSecOps.


