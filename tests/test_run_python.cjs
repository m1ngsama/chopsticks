"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const launcher = require("../scripts/run-python.cjs");

test("uses native Python command conventions on each platform", () => {
  const existing = new Set([
    "C:\\Windows\\py.exe",
    "C:\\Python312\\python.exe",
  ]);
  const windows = launcher.pythonCandidates(
    "win32",
    {
      SystemRoot: "C:\\Windows",
      Path: ".;relative;C:\\Python312;C:\\Windows",
    },
    (candidate) => existing.has(candidate),
  );
  assert.deepEqual(windows, [
    {
      command: "C:\\Windows\\py.exe",
      display: "py -3",
      prefix: ["-3"],
    },
    {
      command: "C:\\Python312\\python.exe",
      display: "python",
      prefix: [],
    },
  ]);
  assert.deepEqual(launcher.pythonCandidates("linux"), [
    { command: "python3", display: "python3", prefix: [] },
    { command: "python", display: "python", prefix: [] },
  ]);
});

test("skips implicit and relative Windows PATH entries", () => {
  const checked = [];
  const resolved = launcher.resolveWindowsExecutable(
    "python",
    { Path: ";.;relative;C:\\TrustedPython" },
    (candidate) => {
      checked.push(candidate);
      return true;
    },
  );

  assert.equal(resolved, "C:\\TrustedPython\\python.exe");
  assert.deepEqual(checked, ["C:\\TrustedPython\\python.exe"]);
});

test("rejects an old interpreter and selects the next supported one", () => {
  const calls = [];
  const probe = (command, arguments_) => {
    calls.push([command, arguments_]);
    return command === "python3"
      ? { error: null, status: 0, stdout: "3.7.17\n" }
      : { error: null, status: 0, stdout: "3.12.11\n" };
  };

  const result = launcher.findPython("linux", probe);

  assert.deepEqual(result.candidate, {
    command: "python",
    display: "python",
    prefix: [],
  });
  assert.deepEqual(result.version, [3, 12, 11]);
  assert.equal(calls.length, 2);
  assert.deepEqual(calls[0][1].slice(0, 1), ["-c"]);
  assert.match(
    launcher.failureMessage(result.attempts),
    /python3: found 3\.7\.17/,
  );
});

test("passes the launcher prefix and every user argument without a shell", () => {
  let invocation;
  const child = {};
  const spawnProcess = (command, arguments_, options) => {
    invocation = { command, arguments_, options };
    return child;
  };

  const result = launcher.launchPython(
    { command: "C:\\Windows\\py.exe", display: "py -3", prefix: ["-3"] },
    ["-B", "script with spaces.py", "--value", "a;b"],
    spawnProcess,
  );

  assert.equal(result, child);
  assert.deepEqual(invocation, {
    command: "C:\\Windows\\py.exe",
    arguments_: ["-3", "-B", "script with spaces.py", "--value", "a;b"],
    options: { stdio: "inherit", windowsHide: true },
  });
});

test("maps child signals to conventional shell exit statuses", () => {
  assert.equal(launcher.signalExitCode("SIGINT"), 130);
  assert.equal(launcher.signalExitCode("NOT_A_SIGNAL"), 1);
});
