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

  // Extract the tariff_id query parameter (if provided)
  const tariffIdRaw = event.queryStringParameters?.tariff_id;
  console.log("Tariff ID received from event:", tariffIdRaw);

  // Extract and validate the optional 'limit' query parameter
  const limitRaw = event.queryStringParameters?.limit;
  let limitClause = "";
  if (limitRaw !== undefined && limitRaw !== null && limitRaw !== "") {
    const limitNumber = Number(limitRaw);
    if (isNaN(limitNumber) || limitNumber <= 0) {
      console.error("Invalid limit parameter provided:", limitRaw);
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message: "Invalid limit parameter" }),
      };
    }
    console.log("Using limit parameter:", limitNumber);
    limitClause = `LIMIT ${limitNumber}`;
  }

  // Prepare SQL literal for tariff_id. Default to "NULL"
  let tariffIdSqlLiteral = "NULL";
  if (tariffIdRaw !== undefined && tariffIdRaw !== null && tariffIdRaw !== "") {
    // Attempt conversion to a number
    const tariffIdNumber = Number(tariffIdRaw);
    if (isNaN(tariffIdNumber)) {
      console.error(
        "Invalid tariff ID provided. Not a valid number:",
        tariffIdRaw
      );
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message: "Invalid tariff ID" }),
      };
    }
    console.log("Converted Tariff ID to number:", tariffIdNumber);
    tariffIdSqlLiteral = tariffIdNumber.toString();
  }

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

  // Prepare the SQL query dynamically using the provided tariff ID.
  // It will use a filter when a valid tariff ID is provided, or get all rows (NULL)
  const sql = `
    WITH test_values AS (
      SELECT 
        ${tariffIdSqlLiteral} AS tariff_id  -- Set this to a specific ID to filter, or NULL to get all
    )
    SELECT 
      t.TARIFF_ID, 
      t.TARIFF_NAME, 
      b.BONUS_NAME, 
      b.BONUS_VALUE, 
      bd.BONUS_DURATION 
    FROM DDS.DDS_SCHEMA.TARIFFS t
    INNER JOIN DDS.DDS_SCHEMA.TARIFF_WITH_BONUSES tb 
      ON t.TARIFF_ID = tb.TARIFF_ID
    INNER JOIN DDS.DDS_SCHEMA.BONUSES b 
      ON tb.BONUS_ID = b.BONUS_ID
    INNER JOIN DDS.DDS_SCHEMA.BONUS_DURATION bd 
      ON b.BONUS_DURATION_ID = bd.BONUS_DURATION_ID
    JOIN test_values tv 
      ON (tv.tariff_id IS NULL OR t.TARIFF_ID = tv.tariff_id) -- Optional filtering
    ORDER BY t.TARIFF_ID, b.BONUS_NAME
    ${limitClause};
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
