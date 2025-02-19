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
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message: "Secret retrieval failed" }),
    };
  }

  console.log("Snowflake secret retrieved successfully.");

  // Initialize (or reinitialize) SnowflakeRepository with the secret
  const repo = new SnowflakeRepository(secret);
  console.log("SnowflakeRepository initialized for the handler.");

  // Extract query parameters from the event (if provided) and convert to SQL literal or NULL
  // TODO: Sanitize the query parameters
  // TODO: Validate the query parameters
  const qs = event.queryStringParameters || {};
  const date_collected = qs.date_collected ? `'${qs.date_collected}'` : "NULL";
  const provider_name = qs.provider_name ? `'${qs.provider_name}'` : "NULL";
  const provider_source = qs.provider_source
    ? `'${qs.provider_source}'`
    : "NULL";
  const connectivity_type = qs.connectivity_type
    ? `'${qs.connectivity_type}'`
    : "NULL";
  const street = qs.street ? `'${qs.street}'` : "NULL";
  const city = qs.city ? `'${qs.city}'` : "NULL";
  const zip = qs.zip ? `'${qs.zip}'` : "NULL";

  // Extract and validate optional 'limit' query parameter
  const limitRaw = qs.limit;
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
  } else {
    const defaultLimit = 100; // Default fallback limit value
    console.log(
      "No limit parameter provided, using default limit:",
      defaultLimit
    );
    limitClause = `LIMIT ${defaultLimit}`;
  }

  // Build the SQL query dynamically using the provided values (or SQL NULL if not provided)
  const sql = `
WITH test_values AS (
    SELECT 
        ${date_collected} AS date_collected,
        ${provider_name} AS provider_name,
        ${provider_source} AS provider_source,
        ${connectivity_type} AS connectivity_type,
        ${street} AS street,
        ${city} AS city,
        ${zip} AS zip
)
SELECT 
    t.TARIFF_ID,
    t.TARIFF_NAME,
    t.NOMINAL_PRICE,
    t.DISCOUNTED_PRICE,
    t.CONTRACT_DURATION,
    t.UPLOAD_RATE,
    t.DOWNLOAD_RATE,
    p.PROVIDER_NAME,
    p.PROVIDER_SOURCE,
    c.CONNECTIVITY_NAME,
    a.STREET,
    a.CITY,
    a.ZIP,
    o.DATE_COLLECTED
FROM DDS.DDS_SCHEMA.TARIFFS t
JOIN DDS.DDS_SCHEMA.PROVIDERS p
    ON t.PROVIDER_ID = p.PROVIDER_ID
JOIN DDS.DDS_SCHEMA.CONNECTIVITY_TYPES c
    ON t.CONNECTIVITY_ID = c.CONNECTIVITY_ID
JOIN DDS.DDS_SCHEMA.OFFER o
    ON t.TARIFF_ID = o.TARIFF_ID
JOIN DDS.DDS_SCHEMA.ADDRESSES a
    ON o.ADDRESS_ID = a.ADDRESS_ID
JOIN test_values tv
    ON (COALESCE(tv.date_collected, o.DATE_COLLECTED) = o.DATE_COLLECTED)
    AND (COALESCE(tv.provider_name, p.PROVIDER_NAME) = p.PROVIDER_NAME)
    AND (COALESCE(tv.provider_source, p.PROVIDER_SOURCE) = p.PROVIDER_SOURCE)
    AND (COALESCE(tv.connectivity_type, c.CONNECTIVITY_NAME) = c.CONNECTIVITY_NAME)
    AND (COALESCE(tv.street, a.STREET) = a.STREET)
    AND (COALESCE(tv.city, a.CITY) = a.CITY)
    AND (COALESCE(tv.zip, a.ZIP) = a.ZIP)
ORDER BY t.TARIFF_ID
${limitClause};
  `;

  console.log("Executing Snowflake query:");
  console.log(sql);

  try {
    await repo.connect();
    const rows = await repo.executeQuery(sql);
    console.log("Query executed successfully. Rows: ", JSON.stringify(rows));

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
    console.error("Error executing query:", error);
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
