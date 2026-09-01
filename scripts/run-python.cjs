#!/usr/bin/env node
"use strict";

const os = require("node:os");
const { spawn, spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const MINIMUM_VERSION = Object.freeze([3, 8, 0]);
const PROBE_PROGRAM =
  "import sys; print('%d.%d.%d' % tuple(sys.version_info[:3]))";

function environmentValue(environment, requestedName) {
  const name = Object.keys(environment).find(
    (candidate) => candidate.toLowerCase() === requestedName.toLowerCase(),
  );
  return name ? environment[name] : undefined;
}

function regularFile(candidate) {
  try {
    return fs.statSync(candidate).isFile();
  } catch {
    return false;
  }
}

function resolveWindowsExecutable(
  name,
  environment = process.env,
  isFile = regularFile,
) {
  const directories = [];
  const systemRoot = environmentValue(environment, "SystemRoot");
  if (name === "py" && systemRoot && path.win32.isAbsolute(systemRoot)) {
    directories.push(systemRoot);
  }
  const searchPath = environmentValue(environment, "PATH") || "";
  directories.push(...searchPath.split(path.win32.delimiter));

  const visited = new Set();
  for (const rawDirectory of directories) {
    const directory = rawDirectory.trim().replace(/^"(.*)"$/, "$1");
    if (!path.win32.isAbsolute(directory)) {
      continue;
    }
    const candidate = path.win32.join(directory, `${name}.exe`);
    const key = candidate.toLowerCase();
    if (!visited.has(key) && isFile(candidate)) {
      return candidate;
    }
    visited.add(key);
  }
  return null;
}

function pythonCandidates(
  platform = process.platform,
  environment = process.env,
  isFile = regularFile,
) {
  if (platform === "win32") {
    return [
      {
        command: resolveWindowsExecutable("py", environment, isFile),
        display: "py -3",
        prefix: ["-3"],
      },
      {
        command: resolveWindowsExecutable("python", environment, isFile),
        display: "python",
        prefix: [],
      },
    ];
  }
  return [
    { command: "python3", display: "python3", prefix: [] },
    { command: "python", display: "python", prefix: [] },
  ];
}

function parseVersion(output) {
  const match = String(output || "")
    .trim()
    .match(/^(\d+)\.(\d+)\.(\d+)$/);
  return match ? match.slice(1).map(Number) : null;
}

function versionAtLeast(version, minimum = MINIMUM_VERSION) {
  for (let index = 0; index < minimum.length; index += 1) {
    if (version[index] !== minimum[index]) {
      return version[index] > minimum[index];
    }
  }
  return true;
}

function describeCandidate(candidate) {
  return (
    candidate.display || [candidate.command, ...candidate.prefix].join(" ")
  );
}

function findPython(platform = process.platform, probe = spawnSync) {
  const attempts = [];
  for (const candidate of pythonCandidates(platform)) {
    if (!candidate.command) {
      attempts.push({ candidate, version: null, reason: "not found" });
      continue;
    }
    const result = probe(
      candidate.command,
      [...candidate.prefix, "-c", PROBE_PROGRAM],
      {
        encoding: "utf8",
        maxBuffer: 1024 * 1024,
        timeout: 5000,
        windowsHide: true,
      },
    );
    const version =
      !result.error && result.status === 0 ? parseVersion(result.stdout) : null;
    if (version && versionAtLeast(version)) {
      return { candidate, version, attempts };
    }
    attempts.push({
      candidate,
      version,
      reason: result.error ? result.error.message : null,
    });
  }
  return { candidate: null, version: null, attempts };
}

function failureMessage(attempts) {
  const details = attempts
    .map(({ candidate, version }) => {
      const found = version ? ` found ${version.join(".")}` : " unavailable";
      return `${describeCandidate(candidate)}:${found}`;
    })
    .join("; ");
  return `Python 3.8 or newer is required (${details}).`;
}

function launchPython(candidate, arguments_, spawnProcess = spawn) {
  return spawnProcess(candidate.command, [...candidate.prefix, ...arguments_], {
    stdio: "inherit",
    windowsHide: true,
  });
}

function signalExitCode(signal) {
  const number = os.constants.signals[signal];
  return number ? 128 + number : 1;
}

function main(arguments_ = process.argv.slice(2)) {
  const discovery = findPython();
  if (!discovery.candidate) {
    console.error(failureMessage(discovery.attempts));
    process.exitCode = 127;
    return;
  }

  const child = launchPython(discovery.candidate, arguments_);
  const signals =
    process.platform === "win32"
      ? ["SIGINT", "SIGTERM"]
      : ["SIGHUP", "SIGINT", "SIGTERM"];
  const handlers = new Map();

  function removeSignalHandlers() {
    for (const [signal, handler] of handlers) {
      process.off(signal, handler);
    }
  }

  for (const signal of signals) {
    const handler = () => {
      if (!child.killed) {
        child.kill(signal);
      }
    };
    handlers.set(signal, handler);
    process.on(signal, handler);
  }

  child.once("error", (error) => {
    removeSignalHandlers();
    console.error(
      `Cannot start ${describeCandidate(discovery.candidate)}: ${error.message}`,
    );
    process.exitCode = 127;
  });
  child.once("exit", (code, signal) => {
    removeSignalHandlers();
    if (!signal) {
      process.exitCode = code === null ? 1 : code;
      return;
    }
    if (process.platform === "win32") {
      process.exitCode = signalExitCode(signal);
      return;
    }
    try {
      process.kill(process.pid, signal);
    } catch {
      process.exitCode = signalExitCode(signal);
    }
  });
}

if (require.main === module) {
  main();
}

module.exports = {
  MINIMUM_VERSION,
  failureMessage,
  findPython,
  launchPython,
  parseVersion,
  pythonCandidates,
  resolveWindowsExecutable,
  signalExitCode,
  versionAtLeast,
};
