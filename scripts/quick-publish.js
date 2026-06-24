// ============================================================
// Mizuki Blog - One-Click Publish (Node.js)
// Usage: node scripts/quick-publish.js
//        (interactive mode - just follow the prompts)
//
//   Or:  node scripts/quick-publish.js "D:/path/to/file.md"
// ============================================================

import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";
import readline from "node:readline";

const PROJECT_DIR = path.resolve(import.meta.dirname, "..");
const POSTS_DIR = path.join(PROJECT_DIR, "src", "content", "posts");

function ask(rl, question, defaultVal = "") {
  return new Promise((resolve) => {
    const prompt = defaultVal ? `${question} [${defaultVal}]: ` : `${question}: `;
    rl.question(prompt, (answer) => {
      resolve(answer.trim() || defaultVal);
    });
  });
}

function getToday() {
  const d = new Date();
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

function safeFileName(inputPath) {
  const basename = path.basename(inputPath, path.extname(inputPath));
  // Replace spaces/special chars with hyphens, keep only safe chars
  let safe = basename
    .replace(/\s+/g, "-")
    .replace(/[^a-zA-Z0-9一-鿿_.-]/g, "")
    .replace(/--+/g, "-")
    .toLowerCase();

  if (!safe || safe.length < 3) {
    const ts = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
    safe = `post-${ts}`;
  }
  return safe + ".md";
}

function extractTitle(content) {
  // Try to extract the first H1 heading
  const h1 = content.match(/^#\s+(.+)$/m);
  if (h1) return h1[1].trim();

  // Try frontmatter title
  const fm = content.match(/^---\s*\ntitle:\s*(.+)$/m);
  if (fm) return fm[1].trim().replace(/['"]/g, "");

  return "";
}

function hasFrontmatter(content) {
  return /^---\s*\n/.test(content);
}

function buildFrontmatter({ title, published, description, tags, category }) {
  let fm = "---\n";
  fm += `title: ${title}\n`;
  fm += `published: ${published}\n`;
  fm += `description: ${description}\n`;
  if (tags) {
    fm += `tags: [${tags}]\n`;
  }
  if (category) {
    fm += `category: ${category}\n`;
  }
  fm += "draft: false\n";
  fm += "---\n\n";
  return fm;
}

function buildContent(inputContent, fm) {
  // Remove existing frontmatter if present, add our own
  let body = inputContent;
  if (hasFrontmatter(body)) {
    body = body.replace(/^---[\s\S]*?---\s*\n*/, "");
  }
  return fm + body;
}

// ── Main ─────────────────────────────────────────────────
async function main() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  console.log("");
  console.log("================================================");
  console.log("   Mizuki Blog - One-Click Publish");
  console.log("================================================");
  console.log("");

  // Step 1: Get file path
  let inputFile = process.argv[2] || "";
  if (!inputFile) {
    inputFile = await ask(rl, "  Drag your .md file here or type path");
    inputFile = inputFile.replace(/['"]/g, "");
  }

  if (!fs.existsSync(inputFile)) {
    console.log(`\n  [ERROR] File not found: ${inputFile}`);
    rl.close();
    process.exit(1);
  }

  const rawContent = fs.readFileSync(inputFile, "utf-8");
  const autoTitle = extractTitle(rawContent);

  console.log(`\n  Source: ${path.basename(inputFile)}`);

  // Step 2: Collect article info
  console.log("\n[Step 2/4] Article info:");
  console.log("----------------------------------------");

  const title = await ask(rl, "  Title", autoTitle);
  const today = getToday();
  const published = await ask(rl, "  Published date", today);
  const description = await ask(rl, "  Description");
  const tagsInput = await ask(rl, "  Tags (comma separated)");
  const category = await ask(rl, "  Category");

  // Step 3: Confirm
  console.log("\n[Step 3/4] Confirm:");
  console.log("----------------------------------------");
  console.log(`  Title:       ${title}`);
  console.log(`  Published:   ${published}`);
  console.log(`  Description: ${description}`);
  console.log(`  Tags:        ${tagsInput || "(none)"}`);
  console.log(`  Category:    ${category || "(none)"}`);
  console.log("");

  const confirm = await ask(rl, "  Publish now?", "Y");
  if (confirm.toLowerCase() !== "y" && confirm !== "") {
    console.log("  Cancelled.");
    rl.close();
    process.exit(0);
  }

  // Step 4: Generate file
  console.log("\n[Step 4/4] Publishing...");
  console.log("----------------------------------------");

  const fm = buildFrontmatter({ title, published, description, tags: tagsInput, category });
  const outputContent = buildContent(rawContent, fm);
  const safeName = safeFileName(inputFile);
  const outputPath = path.join(POSTS_DIR, safeName);

  fs.writeFileSync(outputPath, outputContent, "utf-8");
  console.log(`  [OK] Created: src/content/posts/${safeName}`);

  // Git commit
  try {
    const escapedName = safeName.replace(/"/g, '\\"');
    execSync(`git add "src/content/posts/${escapedName}"`, { cwd: PROJECT_DIR, stdio: "pipe" });
    execSync(`git commit -m "feat: add ${title.replace(/"/g, '\\"')}"`, { cwd: PROJECT_DIR, stdio: "pipe" });
    console.log("  [OK] Committed");
  } catch (e) {
    console.log(`  [WARN] Git commit failed: ${e.message}`);
  }

  // Git push
  console.log("\n  Pushing to GitHub...");
  try {
    execSync("git push origin master", { cwd: PROJECT_DIR, stdio: "inherit" });
    console.log("\n================================================");
    console.log("  [OK] Published successfully!");
    console.log("  Vercel will auto-deploy soon.");
    console.log("================================================");
  } catch (e) {
    console.log("\n  [FAIL] Push failed. Check your proxy/VPN and retry:");
    console.log("    git push origin master");
  }

  console.log("");
  rl.close();
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
