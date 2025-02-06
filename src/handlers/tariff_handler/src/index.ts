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

  // Extract query parameters from the event (if provided)
  const qs = event.queryStringParameters || {};
  // Use defaults if certain parameters are not provided
  const date_collected = qs.date_collected || "2025-02-05";
  const provider_name = qs.provider_name || "Telekom";
  const provider_source = qs.provider_source || "www.telekom.de";
  const connectivity_type = qs.connectivity_type || "dsl";
  const street = qs.street || "Gabelsbergerstr. 51";
  const city = qs.city || "München";
  const zip = qs.zip || "80333";

  // Build the SQL query dynamically using provided or default values
  const sql = `
WITH test_values AS (
    SELECT 
        '${date_collected}' AS date_collected,
        '${provider_name}' AS provider_name,
        '${provider_source}' AS provider_source,
        '${connectivity_type}' AS connectivity_type,
        '${street}' AS street,
        '${city}' AS city,
        '${zip}' AS zip
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
ORDER BY t.TARIFF_ID;
  `;

  console.log("Executing Snowflake query:");
  console.log(sql);

  try {
    await repo.connect();
    const rows = await repo.executeQuery(sql);
    console.log("Query executed successfully. Rows: ", JSON.stringify(rows));
    return {
      statusCode: 200,
      body: JSON.stringify(rows),
    };
  } catch (error) {
    console.error("Error executing query:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal Server Error" }),
    };
  }
};
