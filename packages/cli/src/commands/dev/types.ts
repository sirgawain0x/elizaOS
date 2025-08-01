import type { ChildProcess } from 'node:child_process';

/**
 * Dev command types and interfaces
 */

/**
 * Development server options
 */
export interface DevOptions {
  port?: number;
  configDir?: string;
  character?: string[];
  configure?: boolean;
}

/**
 * Server process management interface
 */
export interface ServerProcess {
  process: ChildProcess | null;
  stop(): Promise<void>;
  start(args?: string[]): Promise<void>;
  restart(args?: string[]): Promise<void>;
}

/**
 * File watcher configuration
 */
export interface WatcherConfig {
  ignored: string[];
  ignoreInitial: boolean;
  persistent: boolean;
  followSymlinks: boolean;
  depth: number;
  usePolling: boolean;
  interval: number;
}

/**
 * Development context information
 */
export interface DevContext {
  directory: string;
  directoryType: import('@/src/utils/directory-detection').DirectoryInfo;
  watchDirectory: string;
  buildRequired: boolean;
}

/**
 * File change event
 */
export interface FileChangeEvent {
  type: 'add' | 'change' | 'unlink';
  path: string;
  stats?: import('node:fs').Stats;
}

/**
 * Build result
 */
export interface BuildResult {
  success: boolean;
  duration: number;
  error?: Error;
}
