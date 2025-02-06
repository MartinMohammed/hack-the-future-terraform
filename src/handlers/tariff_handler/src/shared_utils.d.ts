declare module "shared_utils" {
  export interface SnowflakeConfig {
    account: string;
    username: string;
    password: string;
    database: string;
    schema: string;
    warehouse: string;
  }

  export class SnowflakeRepository {
    constructor(config: SnowflakeConfig);
    connect(): Promise<void>;
    executeQuery<T = any>(query: string): Promise<T[]>;
    disconnect(): Promise<void>;
  }

  export function getSecret(secretName: string): Promise<any>;
}
