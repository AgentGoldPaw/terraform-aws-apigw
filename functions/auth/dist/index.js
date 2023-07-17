"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const client_secrets_manager_1 = require("@aws-sdk/client-secrets-manager");
const client = new client_secrets_manager_1.SecretsManagerClient({ region: 'us-west-2' });
async function handler(event) {
    const response = {
        isAuthorized: false,
    };
    const cmd = new client_secrets_manager_1.GetSecretValueCommand({
        SecretId: process.env.SECRET_NAME,
    });
    const secretValue = await client.send(cmd);
    const apiKey = secretValue.SecretString;
    if (event.headers[process.env.API_KEY_HEADER] === apiKey) {
        response.isAuthorized = true;
    }
    return response;
}
exports.handler = handler;
//# sourceMappingURL=index.js.map