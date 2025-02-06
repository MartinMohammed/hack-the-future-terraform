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

  // NEW: Extract the logical date from the event payload instead of process.env
  const logicalDate = event.LOGICAL_DATE;
  if (!logicalDate) {
    console.error("Missing LOGICAL_DATE in event payload.");
    return {
      statusCode: 400,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        message: "Missing LOGICAL_DATE in event payload",
      }),
    };
  }
  const [loadYear, loadMonth, loadDay] = logicalDate.split("-");
  const stagePath = `@hack_the_future_data_stage/staging/yyyy=${loadYear}/mm=${loadMonth}/dd=${loadDay}/telekom.json`;
  console.log("Logical date from event:", logicalDate);
  console.log("Stage path set to:", stagePath);

  // Build the SQL query dynamically using a transaction wrapper so that
  // all the MERGE statements are executed as one atomic operation.
  const sql = `
    BEGIN

    MERGE INTO ADDRESSES a
    USING (
        SELECT DISTINCT
            t.$1:address:street::string AS STREET,
            t.$1:address:city::string AS CITY,
            t.$1:address:postal_code::string AS ZIP
        FROM ${stagePath} t
    ) src
    ON a.STREET = src.STREET 
    AND a.CITY = src.CITY 
    AND a.ZIP = src.ZIP  -- Check if the address already exists
    WHEN NOT MATCHED THEN
        INSERT (STREET, CITY, ZIP)
        VALUES (src.STREET, src.CITY, src.ZIP);

    MERGE INTO PROVIDERS p
    USING (
        SELECT DISTINCT
            tarif.value:provider::string AS PROVIDER_NAME,
            t.$1:source::string AS PROVIDER_SOURCE
        FROM ${stagePath} t,
             LATERAL FLATTEN(input => t.$1:tarifs) tarif
    ) src
    ON p.PROVIDER_NAME = src.PROVIDER_NAME  -- Check if provider already exists
    WHEN NOT MATCHED THEN
        INSERT (PROVIDER_NAME, PROVIDER_SOURCE)
        VALUES (src.PROVIDER_NAME, src.PROVIDER_SOURCE);

    MERGE INTO CONNECTIVITY_TYPES c
    USING (
        SELECT DISTINCT tarif.value:type::string AS CONNECTIVITY_NAME
        FROM ${stagePath} t,
             LATERAL FLATTEN(input => t.$1:tarifs) tarif
    ) src
    ON c.CONNECTIVITY_NAME = src.CONNECTIVITY_NAME  -- Check for duplicates
    WHEN NOT MATCHED THEN
        INSERT (CONNECTIVITY_NAME)
        VALUES (src.CONNECTIVITY_NAME);

    MERGE INTO TARIFFS t
    USING (
        SELECT
            p.PROVIDER_ID,
            c.CONNECTIVITY_ID,
            tarif.value:name::string AS TARIFF_NAME,
            tarif.value:price:nominal_price::float AS NOMINAL_PRICE,
            tarif.value:price:discounted_price::float AS DISCOUNTED_PRICE,
            tarif.value:contract_details:runtime::int AS CONTRACT_DURATION,
            tarif.value:contract_details:ul_max::float AS UPLOAD_RATE,
            tarif.value:contract_details:dl_max::float AS DOWNLOAD_RATE
        FROM ${stagePath} t,
             LATERAL FLATTEN(input => t.$1:tarifs) tarif
        JOIN PROVIDERS p
          ON p.PROVIDER_NAME = tarif.value:provider::string
        JOIN CONNECTIVITY_TYPES c
          ON c.CONNECTIVITY_NAME = tarif.value:type::string
        WHERE t.$1:date::date = DATE '${logicalDate}'
    ) src
    ON t.TARIFF_NAME = src.TARIFF_NAME
    AND t.PROVIDER_ID = src.PROVIDER_ID
    AND t.CONNECTIVITY_ID = src.CONNECTIVITY_ID
    AND t.NOMINAL_PRICE = src.NOMINAL_PRICE
    AND t.DISCOUNTED_PRICE = src.DISCOUNTED_PRICE
    AND t.CONTRACT_DURATION = src.CONTRACT_DURATION
    AND t.UPLOAD_RATE = src.UPLOAD_RATE
    AND t.DOWNLOAD_RATE = src.DOWNLOAD_RATE  -- Check if tariff already exists
    WHEN NOT MATCHED THEN
        INSERT (
            PROVIDER_ID, 
            CONNECTIVITY_ID, 
            TARIFF_NAME, 
            NOMINAL_PRICE, 
            DISCOUNTED_PRICE, 
            CONTRACT_DURATION, 
            UPLOAD_RATE, 
            DOWNLOAD_RATE
        )
        VALUES (
            src.PROVIDER_ID,
            src.CONNECTIVITY_ID,
            src.TARIFF_NAME,
            src.NOMINAL_PRICE,
            src.DISCOUNTED_PRICE,
            src.CONTRACT_DURATION,
            src.UPLOAD_RATE,
            src.DOWNLOAD_RATE
        );

    MERGE INTO BONUS_DURATION bd
    USING (
        SELECT DISTINCT 
            boni.value:duration::int AS BONUS_DURATION
        FROM ${stagePath} t,
             LATERAL FLATTEN(input => t.$1:tarifs) tarif,
             LATERAL FLATTEN(input => tarif.value:bonis) boni
        WHERE boni.value:duration IS NOT NULL
          AND t.$1:date::date = DATE '${logicalDate}'
    ) src
    ON bd.BONUS_DURATION = src.BONUS_DURATION  -- Check if duration already exists
    WHEN NOT MATCHED THEN
        INSERT (BONUS_DURATION)
        VALUES (src.BONUS_DURATION);

    MERGE INTO BONUSES b
    USING (
        SELECT DISTINCT
            boni.value:name::string AS BONUS_NAME,
            boni.value:value::float AS BONUS_VALUE,
            bd.BONUS_DURATION_ID
        FROM ${stagePath} t,
             LATERAL FLATTEN(input => t.$1:tarifs) tarif,
             LATERAL FLATTEN(input => tarif.value:bonis) boni
        JOIN BONUS_DURATION bd
          ON bd.BONUS_DURATION = boni.value:duration::int
        WHERE t.$1:date::date = DATE '${logicalDate}'
    ) src
    ON b.BONUS_NAME = src.BONUS_NAME 
    AND b.BONUS_VALUE = src.BONUS_VALUE  -- Check if bonus already exists
    WHEN NOT MATCHED THEN
        INSERT (BONUS_NAME, BONUS_VALUE, BONUS_DURATION_ID)
        VALUES (src.BONUS_NAME, src.BONUS_VALUE, src.BONUS_DURATION_ID);

    MERGE INTO TARIFF_WITH_BONUSES tb
    USING (
        SELECT 
            tarr.TARIFF_ID,
            b.BONUS_ID
        FROM (
            SELECT 
                tarif.value['name']::string AS TARIFF_NAME,
                boni.value['name']::string AS BONUS_NAME,
                boni.value['value']::float AS BONUS_VALUE
            FROM ${stagePath} t,
                 LATERAL FLATTEN(input => t.$1:tarifs) tarif,
                 LATERAL FLATTEN(input => tarif.value:bonis) boni
            WHERE t.$1:date::date = DATE '${logicalDate}'
        ) f
        JOIN TARIFFS tarr
          ON tarr.TARIFF_NAME = f.TARIFF_NAME
        JOIN BONUSES b
          ON b.BONUS_NAME = f.BONUS_NAME
         AND b.BONUS_VALUE = f.BONUS_VALUE
    ) src
    ON tb.TARIFF_ID = src.TARIFF_ID 
    AND tb.BONUS_ID = src.BONUS_ID  -- Check if mapping already exists
    WHEN NOT MATCHED THEN
        INSERT (TARIFF_ID, BONUS_ID)
        VALUES (src.TARIFF_ID, src.BONUS_ID);

    MERGE INTO OFFER o
    USING (
        SELECT
            a.ADDRESS_ID,
            tarr.TARIFF_ID,
            f.DATE_COLLECTED
        FROM (
            SELECT
                t.$1:address:street::string AS STREET,
                t.$1:address:city::string AS CITY,
                t.$1:address:postal_code::string AS ZIP,
                t.$1:date::date AS DATE_COLLECTED,
                tarif.value['name']::string AS TARIFF_NAME
            FROM ${stagePath} t,
                 LATERAL FLATTEN(input => t.$1:tarifs) tarif
        ) f
        JOIN ADDRESSES a
          ON a.STREET = f.STREET
         AND a.CITY  = f.CITY
         AND a.ZIP   = f.ZIP
        JOIN TARIFFS tarr
          ON tarr.TARIFF_NAME = f.TARIFF_NAME
    ) src
    ON o.ADDRESS_ID = src.ADDRESS_ID
    AND o.TARIFF_ID = src.TARIFF_ID
    AND o.DATE_COLLECTED = src.DATE_COLLECTED  -- Check if the offer already exists
    WHEN NOT MATCHED THEN
        INSERT (ADDRESS_ID, TARIFF_ID, DATE_COLLECTED)
        VALUES (src.ADDRESS_ID, src.TARIFF_ID, src.DATE_COLLECTED);
        
    END;
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
