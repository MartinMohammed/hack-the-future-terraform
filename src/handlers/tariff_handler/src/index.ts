// index.ts
import { SnowflakeRepository, getSecret } from "shared_utils"; // ensure 'shared_utils' is available (or add a declaration file)

const snowflakeSecretName = process.env.SNOWFLAKE_SECRET_NAME;
const awsRegion = process.env.AWS_REGION;

console.log(`Environment AWS_REGION: ${awsRegion}`);
console.log(`Environment SNOWFLAKE_SECRET_NAME: ${snowflakeSecretName}`);

type SnowflakeSecret = {
  account: string;
  username: string;
  password: string;
  database: string;
  schema: string;
  warehouse: string;
};

console.log("Starting to retrieve Snowflake secret...");
// Instead of using top-level await, start the retrieval and save the Promise
const secretPromise: Promise<SnowflakeSecret> = getSecret(
  snowflakeSecretName as string
);
secretPromise

  .then(() => {
    console.log("Snowflake secret retrieval initiated.");
  })
  .catch((err) => {
    console.error("Error initiating secret retrieval:", err);
  });

export const handler = async (event: any): Promise<any> => {
  console.log("Handler invoked.");
  console.log("Event received:", JSON.stringify(event, null, 2));

  let secret: SnowflakeSecret;
  try {
    // Wait for the secret to be retrieved when the handler is invoked.
    secret = await secretPromise;
  } catch (err) {
    console.error("Failed to retrieve secret:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Secret retrieval failed" }),
    };
  }

  console.log("Snowflake secret retrieved successfully.");

  // Initialize (or reinitialize) SnowflakeRepository with the secret
  const repo = new SnowflakeRepository(secret);
  console.log("SnowflakeRepository initialized for the handler.");

  console.log("Executing query: SHOW TABLES");
  try {
    await repo.connect();
    const tables = await repo.executeQuery("SHOW TABLES");
    console.log(
      `Query executed successfully. Tables: ${JSON.stringify(tables)}`
    );
    return {
      statusCode: 200,
      body: JSON.stringify(tables),
    };
  } catch (error) {
    console.error("Error executing query:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal Server Error" }),
    };
  }
};
