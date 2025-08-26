# Usa uma imagem base oficial do Node.js v18, baseada no Alpine Linux
FROM node:18-alpine

# Define o diretório de trabalho dentro do contêiner
WORKDIR /app

# Copia os arquivos de dependência e aproveita o cache do Docker
COPY package*.json ./

# Instala as dependências do projeto
RUN npm install

# Copia o restante dos arquivos da aplicação
COPY . .

# Expõe a porta em que a aplicação roda
EXPOSE 8000

# Comando para iniciar a aplicação quando o contêiner for executado
CMD [ "node", "server.js" ]