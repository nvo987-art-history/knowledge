#!/usr/bin/env node

import fs from "fs";
import path from "path";
import { DOMParser } from "xmldom";

const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const RESET = "\x1b[0m";

let hasError = false;

function error(msg) {
  console.log(`${RED}✗ ${msg}${RESET}`);
  hasError = true;
}

function ok(msg) {
  console.log(`${GREEN}✓ ${msg}${RESET}`);
}

function exists(file) {
  if (!fs.existsSync(file)) {
    error(`${file} missing`);
    return false;
  }
  ok(`${file} exists`);
  return true;
}

/* ---------- JSON ---------- */
function checkJSON(file) {
  if (!exists(file)) return;
  try {
    JSON.parse(fs.readFileSync(file, "utf8"));
    ok(`${file} valid JSON`);
  } catch (e) {
    error(`${file} invalid JSON`);
  }
}

/* ---------- NDJSON ---------- */
function checkNDJSON(file) {
  if (!exists(file)) return;
  const lines = fs.readFileSync(file, "utf8").split("\n").filter(Boolean);
  lines.forEach((line, i) => {
    try {
      JSON.parse(line);
    } catch {
      error(`${file} invalid JSON on line ${i + 1}`);
    }
  });
  if (!hasError) ok(`${file} valid NDJSON`);
}

/* ---------- HTML ---------- */
function checkHTML(file) {
  if (!exists(file)) return;
  const content = fs.readFileSync(file, "utf8");
  if (!content.includes("<!DOCTYPE html>")) {
    error(`${file} missing DOCTYPE`);
  } else {
    ok(`${file} DOCTYPE ok`);
  }
}

/* ---------- XML ---------- */
function checkXML(file) {
  if (!exists(file)) return;
  try {
    new DOMParser().parseFromString(
      fs.readFileSync(file, "utf8"),
      "application/xml"
    );
    ok(`${file} valid XML`);
  } catch {
    error(`${file} invalid XML`);
  }
}

/* ---------- TXT ---------- */
function checkTXT(file) {
  if (!exists(file)) return;
  ok(`${file} readable`);
}

/* ---------- RUN ---------- */

console.log("\nKnowledge domain validation\n");

checkHTML("index.html");

checkJSON("index.knowledge.json");
checkJSON("schema.json");
checkJSON("graph.json");
checkJSON("usage.json");
checkJSON("integrity.json");

checkNDJSON("corpus.ndjson");
checkNDJSON("vectors.ndjson");

checkTXT("robots.txt");
checkXML("sitemap.xml");

console.log("\n----------------------------");

if (hasError) {
  console.log(`${RED}Validation failed${RESET}\n`);
  process.exit(1);
} else {
  console.log(`${GREEN}All checks passed${RESET}\n`);
  }
