import snowflake from "snowflake-sdk";

interface SnowflakeConfig {
  account: string;
  username: string;
  password: string;
  database: string;
  schema: string;
  warehouse: string;
}

export class SnowflakeRepository {
  private connection: snowflake.Connection;

  constructor(private config: SnowflakeConfig) {
    this.connection = snowflake.createConnection({
      account: config.account,
      username: config.username,
      password: config.password,
      database: config.database,
      schema: config.schema,
      warehouse: config.warehouse,
    });
  }

  public async connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.connection.connect((err, conn) => {
        if (err) {
          console.error("Error connecting to Snowflake:", err);
          reject(err);
          return;
        }
        console.log(
          "Successfully connected to Snowflake. Connection ID:",
          conn.getId()
        );
        resolve();
      });
    });
  }

  public async executeQuery<T = any>(query: string): Promise<T[]> {
    return new Promise((resolve, reject) => {
      this.connection.execute({
        sqlText: query,
        complete: (err, stmt, rows) => {
          if (err) {
            console.error("Error executing query:", err);
            reject(err);
            return;
          }
          resolve(rows as T[]);
        },
      });
    });
  }

  public async disconnect(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.connection.destroy((err) => {
        if (err) {
          console.error("Error disconnecting from Snowflake:", err);
          reject(err);
          return;
        }
        console.log("Successfully disconnected from Snowflake");
        resolve();
      });
    });
  }
}

// Example usage:
/*
const snowflakeConfig: SnowflakeConfig = {
  account: process.env.SNOWFLAKE_ACCOUNT || '',
  username: process.env.SNOWFLAKE_USERNAME || '',
  password: process.env.SNOWFLAKE_PASSWORD || '',
  database: process.env.SNOWFLAKE_DATABASE || '',
  schema: process.env.SNOWFLAKE_SCHEMA || '',
  warehouse: process.env.SNOWFLAKE_WAREHOUSE || ''
};

const snowflakeRepo = new SnowflakeRepository(snowflakeConfig);

try {
  await snowflakeRepo.connect();
  const results = await snowflakeRepo.executeQuery('SELECT * FROM MY_TABLE');
  console.log('Query results:', results);
} catch (error) {
  console.error('Error:', error);
} finally {
  await snowflakeRepo.disconnect();
}
*/

// utils.ts
import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from "@aws-sdk/client-secrets-manager";

// Determine the AWS region from the environment (with a fallback if necessary)
const awsRegion = process.env.AWS_REGION || "us-east-1";

// Initialize the Secrets Manager client once per runtime
const secretsClient = new SecretsManagerClient({ region: awsRegion });

/**
 * Retrieves and parses a secret from AWS Secrets Manager.
 *
 * @param secretName - The name or ARN of the secret to retrieve.
 * @returns A promise that resolves to the parsed secret value.
 *
 * @throws An error if the secret name is not defined or if there is an error retrieving or parsing the secret.
 */
export async function getSecret(secretName: string): Promise<any> {
  if (!secretName) {
    console.error("Secret name is not defined");
    throw new Error("Secret name is not defined");
  }

  console.log(`Retrieving secret for secret name: ${secretName}`);
  const command = new GetSecretValueCommand({ SecretId: secretName });
  try {
    const response = await secretsClient.send(command);

    // Log a sanitized version of the response to avoid printing sensitive values
    console.log(
      "Secret retrieval response:",
      JSON.stringify({
        SecretString: response.SecretString ? "***" : undefined,
        SecretBinary: response.SecretBinary ? "***" : undefined,
      })
    );

    if (response.SecretString) {
      const secretValue = JSON.parse(response.SecretString);
      console.log("Secret parsed successfully.");
      return secretValue;
    } else if (response.SecretBinary) {
      const buff = Buffer.from(response.SecretBinary, "base64");
      const secretValue = buff.toString("ascii");
      console.log("Secret binary converted successfully.");
      return secretValue;
    } else {
      console.error("No secret data found in the response.");
      throw new Error("No secret data found in the response.");
    }
  } catch (error) {
    console.error("Error retrieving secret:", error);
    throw error;
  }
}
