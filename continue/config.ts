const replaceEnvVars = <T>(obj: T): T => {
  if (Array.isArray(obj)) {
    return obj.map(item => replaceEnvVars(item)) as T;
  }

  const result = { ...obj };
  for (const key in result) {
    if (typeof result[key] === 'string') {
      // Replace placeholders in the format ${VAR_NAME} with the value from process.env
      result[key] = result[key].replace(/\$\{(.+?)\}/g, (_, varName: string) =>
        process.env[varName] ?? ''
      );
    } else if (result[key] && typeof result[key] === 'object') {
      // Recursively call replaceEnvVars for nested objects
      result[key] = replaceEnvVars(result[key]);
    }
  }
  return result;
};

export function modifyConfig(config: Config): Config {
  return replaceEnvVars(config);
}
