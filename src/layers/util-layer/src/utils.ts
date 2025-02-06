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
