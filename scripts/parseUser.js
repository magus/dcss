const chalk = require('chalk');
const fetch = require('isomorphic-unfetch');
const fs = require('fs');
const ora = require('ora');
const path = require('path');
const { exec } = require('child_process');

const RAWDATA_PATH = 'http://crawl.akrasiac.org/rawdata';
const CACHE_DIR = path.join(__dirname, '.cache', path.basename(__filename));

fs.mkdirSync(CACHE_DIR, { recursive: true });

async function run() {
  const [, , username, ...restArgs] = process.argv;
  const search = restArgs.join(' ');
  // const username = 'magusnn';
  // const search = 'scales of the dragon king';

  if (!username) {
    console.error();
    console.error('🤖 Username required. e.g. parseUser magusnn');
    process.exit(1);
  } else if (!search) {
    console.error();
    console.error('🤖 Search for what? e.g. parseUser magusnn dragon');
    process.exit(1);
  }

  console.info();
  console.info(`🤖 Search [${chalk.cyan(username)}] for [${chalk.yellow(search)}]`);
  const spinner = ora('🤖 Searching...').start();

  const allMorgueFileContent = await getUsernameMorgueContents(username, spinner);

  // console.debug(allMorgueFileContent.length, 'allMorgueFileContent');
  // console.debug(allMorgueFileContent[0]);

  const searchResults = [];

  const promseSearchAllContent = allMorgueFileContent.map(async (morgue) => {
    return new Promise((resolve) => {
      spinner.text = morgue.filename;
      spinner.render();

      const cacheMorguePath = `${CACHE_DIR}/${morgue.filename}`;
      const grepOutput = exec(`cat "${cacheMorguePath}" | grep -B 2 -A 2 -ie "${search}"`, (err, stdout, stderr) => {
        if (err) {
          if (err.code === 1) {
            // Ignore non-zero exit code
            // grep returns a 1 exit code when there are no matches
          } else {
            console.error(err);
          }
          return resolve();
        }

        const grep = stdout.toString();
        searchResults.push({ morgue, grep });
        resolve();
      });
    });
  });

  await Promise.all(promseSearchAllContent);

  spinner.prefixText = '🤖';
  spinner.succeed(`${chalk.green(searchResults.length)} results found.`);
  console.info();

  searchResults.forEach((result, i) => {
    const {
      grep,
      morgue: { filename },
    } = result;

    const cacheMorguePath = `${CACHE_DIR}/${filename}`;

    console.info(`👉 ${chalk.magenta(i + 1)} [${chalk.cyan(filename)}]`);
    console.info(chalk.dim(`${RAWDATA_PATH}/${username}/${filename}`));
    console.info(chalk.dim(cacheMorguePath));

    const wrapedSearchInGrep = grep.replace(new RegExp(search, 'ig'), (match) => {
      return chalk.bold(chalk.yellow(match));
    });
    console.info();
    console.debug(chalk.gray(wrapedSearchInGrep));
  });

  console.info(`🤖 ${chalk.green(searchResults.length)} results found.`);
}

async function getUsernameMorgueContents(username, spinner) {
  const morgueFilenames = await getMorgueFilenames(username);
  // console.debug(morgueFilenames.length, 'morgueFilenames');

  const promiseAllMorgueFileContent = morgueFilenames.map(async (filename) => {
    const content = await cachedMorgue(username, filename, spinner);
    return { filename, content };
  });

  return await Promise.all(promiseAllMorgueFileContent);
}

async function cachedMorgue(username, morgueFilename, spinner) {
  const cacheMorguePath = `${CACHE_DIR}/${morgueFilename}`;

  if (!fs.existsSync(cacheMorguePath)) {
    const morgueUrl = `${RAWDATA_PATH}/${username}/${morgueFilename}`;

    spinner.text = `fetch(${morgueUrl})`;
    spinner.render();

    const resp = await fetch(morgueUrl);
    const respText = await resp.text();

    fs.writeFileSync(cacheMorguePath, respText);
  }

  return fs.readFileSync(cacheMorguePath, { encoding: 'utf8', flag: 'r' });
}

async function getMorgueFilenames(username) {
  const resp = await fetch(`${RAWDATA_PATH}/${username}/?C=M;O=D`);
  const respText = await resp.text();

  const morgueFilenames = [];

  // /href=\"(morgue-magusnn-[0-9\-]*\.txt)\"/g
  const regex = new RegExp(`href=\"(morgue-${username}-[0-9\-]*\.txt)\"`, 'g');

  let match = regex.exec(respText);

  while (match) {
    const [, filename] = match;
    morgueFilenames.push(filename);

    match = regex.exec(respText);
  }

  return morgueFilenames;
}

run();
