/**
 * declare of environment variables
 */
declare namespace NodeJS {
  interface ProcessEnv {
    readonly TZ: string;
  }
}
