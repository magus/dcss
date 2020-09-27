const { execSync } = require('child_process');
const FSUtils = require('./utils/fs');
const PartsUtils = require('./utils/parts');

const TEMPLATE_FILENAME = '_template.rc';
const OUTPUT_FILENAME = 'output/magus.rc';

const RELEASES_LOG = 'RELEASES.md';
const RELEASES_LOG_TEMPLATE = '_template_RELEASES.md';

const GIT_DIRTY = execSync('git status --porcelain').toString().trim();
const GIT_HEAD_SHA = execSync('git rev-parse HEAD').toString().trim();

if (GIT_DIRTY) {
  console.info('🤖 Uncommitted changes. Cannot compile without a valid git SHA.');
  process.exit(1);
}

// ensure output directory
execSync(`rm -rf $(dirname ${OUTPUT_FILENAME})`);
execSync(`mkdir -p $(dirname ${OUTPUT_FILENAME})`);

let OUTPUT_RC = FSUtils.read(TEMPLATE_FILENAME);

// Replace ## Headers with proper part util function output
OUTPUT_RC = PartsUtils.RunRegex(/\#--([^\s]+)(.*)/g, OUTPUT_RC, (headerType, args) => PartsUtils[headerType](args));

// Replace `{{Filename.ext}}` with the file content using PartsUtil.ContentFormatter
OUTPUT_RC = PartsUtils.RunRegex(/{{(.*)}}/g, OUTPUT_RC, (filename) => {
  return PartsUtils.ContentFormatter(filename, FSUtils.read(`parts/${filename}`));
});

FSUtils.write(OUTPUT_FILENAME, OUTPUT_RC);

// grab version from compiled output
// version is set is _template.rc (e.g. #--Begin 1.4)
// then the UNIX epoch ms are appended to make it unique
// e.g. [v1.4.1601160553209] (v1.4 on Sat Sep 26 2020 at 15:49:13 PST)
const [, VERSION] = OUTPUT_RC.match(/\[v(.*?)\]/);

// Parse RELEASES.md and update log and examples
const releaseLogFileContent = FSUtils.read(RELEASES_LOG);
const [, allReleasesContent] = releaseLogFileContent.match(/# Releases((.|[\n])*)/);
const allReleases = allReleasesContent.trim().split('\n');
const [ExampleVersion, ExampleSHA] = allReleases[1].split(' ');

const updatedReleaseLog = PartsUtils.RunRegex(/{{(.*?)}}/g, FSUtils.read(RELEASES_LOG_TEMPLATE), (replaceKey) => {
  return {
    ExampleVersion,
    ExampleSHA,
    GIT_HEAD_SHA,
    AllReleases: [`${VERSION} ${GIT_HEAD_SHA}`, ...allReleases].join('\n'),
  }[replaceKey];
});

FSUtils.write(RELEASES_LOG, updatedReleaseLog);

// Copy content to clipboard
execSync(`cat ${OUTPUT_FILENAME} | pbcopy`);

console.info(`🤖 Generated ${OUTPUT_FILENAME} copied to clipboard! 📋`);
