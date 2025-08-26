#!/bin/bash

# Configurações
IMAGE_NAME="cesar4fun/desafio_winnin"
CONTAINER_NAME="desafio_winnin"
APP_PORT=5005

echo "🚀 Iniciando deploy local..."
echo "📦 Nome da imagem: $IMAGE_NAME"
echo "🐳 Nome do container: $CONTAINER_NAME"
echo "🔌 Porta da aplicação: $APP_PORT"

# Parar container existente
echo "🛑 Parando container existente..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# Construir nova imagem
echo "🔨 Construindo nova imagem..."
docker build -t $IMAGE_NAME:latest .

# Executar container
echo "🐳 Executando container..."
docker run -d \
  -p $APP_PORT:5005 \
  --name $CONTAINER_NAME \
  --restart unless-stopped \
  $IMAGE_NAME:latest

echo "⏳ Aguardando aplicação iniciar..."
sleep 5

# Verificar se a aplicação está respondendo
echo "🔍 Verificando saúde da aplicação..."
if curl -f http://localhost:$APP_PORT/health > /dev/null 2>&1; then
    echo "✅ Deploy concluído com sucesso!"
    echo "🌐 Acesse: http://localhost:$APP_PORT"
    echo "📊 Health check: http://localhost:$APP_PORT/health"
else
    echo "⚠️  A aplicação pode estar iniciando ainda..."
    echo "📋 Verifique os logs: docker logs $CONTAINER_NAME"
fi

echo ""
echo "📋 Comandos úteis:"
echo "   Ver logs: docker logs $CONTAINER_NAME"
echo "   Parar aplicação: docker stop $CONTAINER_NAME"
echo "   Reiniciar: docker restart $CONTAINER_NAME"