import { SnowflakeRepository } from "shared_utils";
import { getSecret } from "shared-utils";
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
const secret: SnowflakeSecret = await getSecret(snowflakeSecretName);
console.log("Snowflake secret retrieved successfully.");

// Initialize SnowflakeRepository
const snowflakeRepository = new SnowflakeRepository(secret);
console.log("SnowflakeRepository initialized successfully.");

export const handler = async (event: any) => {
  console.log("Handler invoked.");
  console.log("Event received:", JSON.stringify(event, null, 2));

  // Re-initialize the snowflake repository (if needed)
  const repo = new SnowflakeRepository(secret);
  console.log("SnowflakeRepository re-initialized for the handler.");

  console.log("Executing query: SHOW TABLES");
  try {
    // connect to snowflake
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
