import { APIGatewayProxyEvent } from 'aws-lambda';
import {
  GetSecretValueCommand,
  SecretsManagerClient,
} from '@aws-sdk/client-secrets-manager';
const client = new SecretsManagerClient({ region: 'us-west-2' });

export async function handler(event: APIGatewayProxyEvent) {
  const response = {
    isAuthorized: false,
  };

  const cmd = new GetSecretValueCommand({
    SecretId: process.env.SECRET_NAME,
  });

  const secretValue = await client.send(cmd);
  const apiKey = secretValue.SecretString;

  if (event.headers[process.env.API_KEY_HEADER] === apiKey) {
    response.isAuthorized = true;
  }

  return response;
}
