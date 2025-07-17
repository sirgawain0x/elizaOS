import { getCliInstallTag, installPlugin, loadPluginModule } from '@/src/utils';
import { detectPluginContext, provideLocalPluginGuidance } from '@/src/utils/plugin-context';
import { logger, type Plugin } from '@elizaos/core';
import { PluginValidation } from '../types';

/**
 * Check if an object has a valid plugin shape
 */
export function isValidPluginShape(obj: any): obj is Plugin {
  if (!obj || typeof obj !== 'object' || !obj.name) {
    return false;
  }
  return !!(
    obj.init ||
    obj.services ||
    obj.providers ||
    obj.actions ||
    obj.evaluators ||
    obj.description
  );
}

/**
 * Load and prepare a plugin for use
 *
 * Handles both local development plugins and published plugins, with automatic installation if needed.
 */
export async function loadAndPreparePlugin(pluginName: string): Promise<Plugin | null> {
  const version = getCliInstallTag();
  let pluginModule: any;
  const context = detectPluginContext(pluginName);

  if (context.isLocalDevelopment) {
    try {
      pluginModule = await loadPluginModule(pluginName);
      if (!pluginModule) {
        logger.error(`Failed to load local plugin ${pluginName}.`);
        provideLocalPluginGuidance(pluginName, context);
        return null;
      }
    } catch (error) {
      logger.error(`Error loading local plugin ${pluginName}: ${error}`);
      provideLocalPluginGuidance(pluginName, context);
      return null;
    }
  } else {
    try {
      pluginModule = await loadPluginModule(pluginName);
      if (!pluginModule) {
        logger.info(`Plugin ${pluginName} not available, installing...`);
        await installPlugin(pluginName, process.cwd(), version);
        pluginModule = await loadPluginModule(pluginName);
      }
    } catch (error) {
      logger.error(`Failed to process plugin ${pluginName}: ${error}`);
      return null;
    }
  }

  if (!pluginModule) {
    logger.error(`Failed to load module for plugin ${pluginName}.`);
    return null;
  }

  // Debug logging for module exports
  logger.debug(`Module exports for ${pluginName}:`, Object.keys(pluginModule));

  // More robust export detection
  let plugin: Plugin | null = null;

  // 1. Check for named export 'plugin'
  if (pluginModule.plugin && isValidPluginShape(pluginModule.plugin)) {
    logger.debug(`Found named export 'plugin' in ${pluginName}`);
    plugin = pluginModule.plugin as Plugin;
  }
  // 2. Check for default export
  else if (pluginModule.default && isValidPluginShape(pluginModule.default)) {
    logger.debug(`Found default export in ${pluginName}`);
    plugin = pluginModule.default as Plugin;
  }
  // 3. Check for direct export (module itself is the plugin)
  else if (isValidPluginShape(pluginModule)) {
    logger.debug(`Module itself is a valid plugin for ${pluginName}`);
    plugin = pluginModule as Plugin;
  }
  // 4. Check for expected function name pattern
  else {
    const expectedFunctionName = `${pluginName
      .replace(/^@elizaos\/plugin-/, '')
      .replace(/^@elizaos\//, '')
      .replace(/-./g, (match) => match[1].toUpperCase())}Plugin`;

    if (
      pluginModule[expectedFunctionName] &&
      isValidPluginShape(pluginModule[expectedFunctionName])
    ) {
      logger.debug(`Found export with expected name '${expectedFunctionName}' in ${pluginName}`);
      plugin = pluginModule[expectedFunctionName] as Plugin;
    }
  }

  // 5. Last resort: check all exports
  if (!plugin) {
    for (const [key, value] of Object.entries(pluginModule)) {
      if (key !== 'default' && isValidPluginShape(value)) {
        logger.debug(`Found valid plugin export '${key}' in ${pluginName}`);
        plugin = value as Plugin;
        break;
      }
    }
  }

  if (!plugin) {
    logger.error(`Could not find a valid plugin export in ${pluginName}.`);
    logger.error(`Available exports: ${Object.keys(pluginModule).join(', ')}`);
    if (pluginModule.default) {
      logger.error(
        `Default export type: ${typeof pluginModule.default}, has name: ${pluginModule.default?.name}`
      );
    }
  }

  return plugin;
}

/**
 * Validate a plugin object
 */
export function validatePlugin(plugin: any): PluginValidation {
  if (!plugin) {
    return { isValid: false, error: 'Plugin is null or undefined' };
  }

  if (!isValidPluginShape(plugin)) {
    return { isValid: false, error: 'Plugin does not have valid shape' };
  }

  return { isValid: true, plugin };
}
