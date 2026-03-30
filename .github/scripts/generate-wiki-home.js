#!/usr/bin/env node
/**
 * Generates wiki/Home.md — a structured table of contents for the GitHub wiki.
 * Run from the repo root: node .github/scripts/generate-wiki-home.js > wiki/Home.md
 */

const fs   = require('fs');
const path = require('path');

const DOCS_ROOT = path.join(__dirname, '../../docs');
const EXCLUDE   = new Set(['_archive', '.DS_Store']);

// ── Helpers ──────────────────────────────────────────────────────────────────

function titleCase(str) {
  return str
    .replace(/[-_]/g, ' ')
    .replace(/\.md$/i, '')
    .replace(/\b\w/g, c => c.toUpperCase());
}

/** Return the first # heading from a markdown file, or fall back to filename. */
function extractTitle(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const match   = content.match(/^#\s+(.+)/m);
    if (match) return match[1].trim().replace(/[`*]/g, '');
  } catch (_) { /* ignore */ }
  return titleCase(path.basename(filePath));
}

/**
 * Convert a docs-relative path to a wiki URL path.
 * GitHub wiki serves files at /<repo>/wiki/<path-without-.md>
 * Relative links in wiki markdown: just strip the leading `docs/` prefix.
 */
function wikiLink(docsRelPath) {
  return docsRelPath.replace(/\.md$/i, '');
}

// ── Walk docs tree ────────────────────────────────────────────────────────────

function walk(dir, relBase = '') {
  const entries = fs.readdirSync(dir, { withFileTypes: true })
    .filter(e => !EXCLUDE.has(e.name) && !e.name.startsWith('.'));

  const files = entries.filter(e => e.isFile()  && e.name.endsWith('.md'));
  const dirs  = entries.filter(e => e.isDirectory());

  return { files, dirs, relBase };
}

// ── Section renderer ──────────────────────────────────────────────────────────

function renderSection(label, dirPath, relBase, depth = 2) {
  const { files, dirs } = walk(dirPath, relBase);
  const lines = [];

  if (files.length || dirs.length) {
    lines.push(`${'#'.repeat(depth)} ${label}\n`);
  }

  files.forEach(f => {
    const rel   = path.join(relBase, f.name);
    const title = extractTitle(path.join(dirPath, f.name));
    lines.push(`- [${title}](${wikiLink(rel)})`);
  });

  dirs.forEach(d => {
    const sub = renderSection(
      titleCase(d.name),
      path.join(dirPath, d.name),
      path.join(relBase, d.name),
      depth + 1,
    );
    if (sub) lines.push('', sub);
  });

  return lines.join('\n');
}

// ── Build output ──────────────────────────────────────────────────────────────

const sections = [];

sections.push(`# mellow.menu — Documentation

> Auto-generated from [\`/docs\`](https://github.com/fkelledy2/smart-menu-rails/tree/main/docs) on every push to \`main\`.

---
`);

// Top-level reference docs
const topFiles = fs.readdirSync(DOCS_ROOT, { withFileTypes: true })
  .filter(e => e.isFile() && e.name.endsWith('.md') && !EXCLUDE.has(e.name));

if (topFiles.length) {
  sections.push('## Reference Docs\n');
  topFiles.forEach(f => {
    const title = extractTitle(path.join(DOCS_ROOT, f.name));
    sections.push(`- [${title}](${wikiLink(f.name)})`);
  });
  sections.push('');
}

// User Guides
const userGuidesDir = path.join(DOCS_ROOT, 'user_guides');
if (fs.existsSync(userGuidesDir)) {
  sections.push(renderSection('User Guides', userGuidesDir, 'user_guides', 2));
  sections.push('');
}

// Feature Specs — by lifecycle stage
const featuresDir = path.join(DOCS_ROOT, 'features');
if (fs.existsSync(featuresDir)) {
  sections.push('## Feature Specs\n');

  const stageOrder = ['completed', 'in_progress', 'todo', 'parked'];
  const stageLabels = {
    completed:   'Completed',
    in_progress: 'In Progress',
    todo:        'Backlog (Todo)',
    parked:      'Parked',
  };

  stageOrder.forEach(stage => {
    const stageDir = path.join(featuresDir, stage);
    if (!fs.existsSync(stageDir)) return;
    const sub = renderSection(
      stageLabels[stage] || titleCase(stage),
      stageDir,
      `features/${stage}`,
      3,
    );
    if (sub) sections.push(sub, '');
  });

  // improvements.md at features root
  const improvementsFile = path.join(featuresDir, 'improvements.md');
  if (fs.existsSync(improvementsFile)) {
    const title = extractTitle(improvementsFile);
    sections.push(`- [${title}](${wikiLink('features/improvements.md')})\n`);
  }
}

// Agent reference
const agentRef = path.join(DOCS_ROOT, 'agent-reference.md');
if (fs.existsSync(agentRef)) {
  // Already included in top-level reference docs above
}

sections.push('---');
sections.push(`*Last synced: auto-updated by CI*`);

process.stdout.write(sections.join('\n'));
