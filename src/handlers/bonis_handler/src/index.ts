// index.ts
import { SnowflakeRepository, getSecret } from "shared_utils"; // ensure 'shared_utils' is available (or add a declaration file)

const snowflakeSecretName = process.env.SNOWFLAKE_SECRET_NAME;
const awsRegion = process.env.AWS_REGION;

console.log(`Environment AWS_REGION: ${awsRegion}`);
console.log(`Environment SNOWFLAKE_SECRET_NAME: ${snowflakeSecretName}`);

if (!snowflakeSecretName) {
  console.error(
    "Error: SNOWFLAKE_SECRET_NAME environment variable is not set."
  );
}

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
    console.log("Waiting for Snowflake secret retrieval...");
    // Wait for the secret to be retrieved when the handler is invoked.
    secret = await secretPromise;
    console.log(
      "Snowflake secret retrieved successfully. (Account:",
      secret.account,
      ")"
    );
  } catch (err) {
    console.error("Failed to retrieve Snowflake secret:", err);
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message: "Secret retrieval failed" }),
    };
  }

  // Initialize SnowflakeRepository with the secret
  const repo = new SnowflakeRepository(secret);
  console.log("SnowflakeRepository initialized for the handler.");

  // Prepare the SQL query dynamically using the provided tariff ID
  const sql = `
   
  `;
  console.log("Prepared SQL query:");
  console.log(sql);

  try {
    console.log("Connecting to Snowflake...");
    await repo.connect();
    console.log("Connected to Snowflake successfully.");

    console.log("Executing query...");
    const rows = await repo.executeQuery(sql);
    console.log(
      "Query executed successfully. Rows received:",
      JSON.stringify(rows)
    );

    try {
      // Attempt to disconnect from Snowflake after successful query
      await repo.disconnect();
      console.log("Disconnected from Snowflake successfully.");
    } catch (disconnectError) {
      console.warn(
        "Warning: Failed to disconnect from Snowflake properly:",
        disconnectError
      );
    }

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(rows),
    };
  } catch (error) {
    console.error("Error during query execution:", error);
    try {
      // Try disconnecting even if an error occurs
      await repo.disconnect();
      console.log("Disconnected from Snowflake after error.");
    } catch (disconnectError) {
      console.error(
        "Error during disconnection after failure:",
        disconnectError
      );
    }
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message: "Internal Server Error" }),
    };
  }
};
