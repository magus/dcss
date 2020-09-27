const { execSync } = require('child_process');
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

// ensure output directory
execSync(`mkdir -p $(dirname ${OUTPUT_FILENAME})`);

let OUTPUT_RC = FSUtils.read(TEMPLATE_FILENAME);

// Replace ## Headers with proper part util function output
OUTPUT_RC = PartsUtils.RunRegex(/\#--([^\s]+)(.*)/g, OUTPUT_RC, (headerType, args) => PartsUtils[headerType](args));

// Replace `{{Filename.ext}}` with the file content using PartsUtil.ContentFormatter
OUTPUT_RC = PartsUtils.RunRegex(/{{(.*)}}/g, OUTPUT_RC, (filename) => {
  return PartsUtils.ContentFormatter(filename, FSUtils.read(path.join(__dirname, `parts/${filename}`)));
});

// grab version from compiled output
// version is set is _template.rc (e.g. #--Begin 1.4)
// then the UNIX epoch ms are appended to make it unique
// e.g. [v1.4.1601160553209] (v1.4 on Sat Sep 26 2020 at 15:49:13 PST)
const [, VERSION] = OUTPUT_RC.match(/\[v(.*?)\]/);

// Get latest past git tag for updating RELEASES.md
const ExampleVersion = execSync('git describe --abbrev=0').toString().trim().replace(/^v/, '');
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
  execSync(`git commit -am  "[v${VERSION}]"`);
  execSync(`git tag -a v${VERSION} -m "[v${VERSION}]"`);
}
