const { execSync } = require('child_process');
const { DateTime } = require('luxon');
const path = require('path');
const FSUtils = require('./utils/fs');
const PartsUtils = require('./utils/parts');

const TEMPLATE_FILENAME = path.join(__dirname, '_template.rc');
const OUTPUT_FILENAME = 'output/magus.rc';

const RAW_RELEASES = path.join(__dirname, '_releases');
const RELEASES_LOG = 'RELEASES.md';
const RELEASES_LOG_TEMPLATE = path.join(__dirname, '_template_RELEASES.md');

const GIT_DIRTY = execSync('git status --porcelain').toString().trim();
const GIT_HEAD_SHA = execSync('git rev-parse HEAD').toString().trim();

const [, , write, commit] = process.argv;

if (write !== '--write') {
  console.info('🤖 Dry running without writing and committing.');
  console.info('🤖 To update files, try `yarn compile --write`');
} else if (commit !== '--commmit') {
  console.info('🤖 Running without committing.');
  console.info('🤖 To commit, try `yarn compile --write --commmit`');
}

if (commit && GIT_DIRTY) {
  console.info('🤖 Uncommitted changes. Cannot compile without a valid git SHA.');
  process.exit(1);
}

// Always increment patch to ensure unique version number
if (commit) {
  // Committed versions (production versions)
  // Use the simple version string without unix epoch ms
  // e.g. v1.4.12
  execSync(`yarn version --no-commit-hooks --no-git-tag-version --patch`);
}

// Grab version from package.json
const packageJson = FSUtils.readJSON('package.json');
const { version } = packageJson;
let VERSION = `v${version}`;

if (!commit) {
  // Only use UNIX epoch ms for local compiles
  // then the UNIX epoch ms are appended to make it unique
  // e.g. v1.4.1601160553209 (v1.4 on Sat Sep 26 2020 at 15:49:13 PST)
  const now = DateTime.local();
  const datetimestamp = now.toFormat('yyyy-M-dd.hh:mm:ssa');
  VERSION = `${VERSION}.${datetimestamp}`;
}

// ensure output directory
execSync(`mkdir -p $(dirname ${OUTPUT_FILENAME})`);

let OUTPUT_RC = FSUtils.read(TEMPLATE_FILENAME);

// Replace ## Headers with proper part util function output
OUTPUT_RC = PartsUtils.RunRegex(/\#--([^\s]+)(.*)/g, OUTPUT_RC, (headerType, args) => PartsUtils[headerType](args));

// Replace `{{Filename.ext}}` with the file content using PartsUtil.ContentFormatter
OUTPUT_RC = PartsUtils.RunRegex(/{{(.*?\..*)}}/g, OUTPUT_RC, (filename) => {
  return PartsUtils.ContentFormatter(filename, FSUtils.read(path.join(__dirname, `parts/${filename}`)));
});

// Replace {{VERSION}} with package.json version
OUTPUT_RC = PartsUtils.RunRegex(/{{VERSION}}/g, OUTPUT_RC, () => VERSION);

// ===============
// RELEASES.md
// ===============

// Get latest past git tag for updating RELEASES.md
const ExampleVersion = execSync('git describe --abbrev=0').toString().trim();
// Update RELEASES.md examples to use last version
const updatedReleaseLog = PartsUtils.RunRegex(
  /{{(.*?)}}/g,
  FSUtils.read(RELEASES_LOG_TEMPLATE),
  (replaceKey) =>
    ({
      ExampleVersion,
      LatestVersion: VERSION,
    }[replaceKey]),
);

if (write) {
  FSUtils.write(OUTPUT_FILENAME, OUTPUT_RC);
  FSUtils.write(RELEASES_LOG, updatedReleaseLog);

  // Copy content to clipboard
  execSync(`cat ${OUTPUT_FILENAME} | pbcopy`);
  console.info(`🤖 Generated ${OUTPUT_FILENAME} copied to clipboard! 📋`);
}

// Commit and tag these changes for Releases
if (commit) {
  // build very simple changelog from commit messages since last version tag
  const lastTag = execSync('git describe --abbrev=0 --tags').toString().trim();
  const changelog = execSync(`git log --format=%B ${lastTag}..HEAD`).toString();
  const message = `[${VERSION}]\n\n${changelog}`;

  execSync(`git commit -am  "${message}"`);
  execSync(`git tag -a ${VERSION} -m "${message}"`);
} else {
  // Revert outputs to prevent accidental commit
  execSync(`git checkout ${OUTPUT_FILENAME}`);
  execSync(`git checkout ${RELEASES_LOG}`);
}
