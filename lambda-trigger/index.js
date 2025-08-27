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