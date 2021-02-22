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
  const hrStartTime = process.hrtime();
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
  const spinner = ora({
    text: 'Searching...',
    prefixText: '🤖',
  }).start();

  let morgueFilenames = [];
  try {
    morgueFilenames = await getMorgueFilenames(username, spinner);
    // console.debug(morgueFilenames.length, 'morgueFilenames');
  } catch (err) {
    spinner.fail(`[${chalk.cyan(username)}] not found. Are you sure you spelled it correctly?`);
    console.error(chalk.dim(`${RAWDATA_PATH}/${username}/?C=M;O=D`));
    process.exit(1);
  }

  const allMorgueFileContent = await getUsernameMorgueContents(username, morgueFilenames, spinner);
  // console.debug(allMorgueFileContent.length, 'allMorgueFileContent');
  // console.debug(allMorgueFileContent[0]);

  if (search === '@time') {
    const parseMorgueResults = await parseMorgues(
      { spinner, allMorgueFileContent, hrStartTime },
      async (morgue) => {
        const timeSeconds = parseMorgueFile('@time', morgue.content);
        return timeSeconds;
      },
      ({ results, searchTime }) => {
        const totalTime = results.reduce((ts, r) => r.timeSeconds + ts, 0);
        const readableTime = secondsToTimeUnits(totalTime);
        console.info(chalk.bold(chalk.yellow(readableTime)));
      },
    );

    console.info(`🤖 ${'Done'}`);
  } else {
    await parseMorgues(
      { spinner, allMorgueFileContent, hrStartTime },
      async (morgue, cacheMorguePath) => {
        return new Promise((resolve) => {
          const grepOutput = exec(
            `cat "${cacheMorguePath}" | grep -B 2 -A 2 -ie "${search}"`,
            (err, stdout, stderr) => {
              if (err) {
                if (err.code === 1) {
                  // Ignore non-zero exit code
                  // grep returns a 1 exit code when there are no matches
                } else {
                  console.error(err);
                }
                return resolve(null);
              }

              const grep = stdout.toString();
              resolve({ morgue, grep });
            },
          );
        });
      },
      (parseMorgueResults) => {
        const searchResults = parseMorgueResults.results.filter((result) => {
          // skip null (empty search results)
          if (!result) {
            return false;
          }

          return true;
        });

        const searchResultMessage = `${chalk.green(searchResults.length)} result${
          searchResults.length > 1 ? 's' : ''
        } found in ${chalk.magenta(allMorgueFileContent.length)} morgue files (${chalk.dim(
          `${parseMorgueResults.searchTime}ms`,
        )}).`;

        spinner.succeed(searchResultMessage);
        console.info();

        searchResults.reverse().forEach((result, i) => {
          const {
            grep,
            morgue: { filename },
          } = result;

          const cacheMorguePath = `${CACHE_DIR}/${filename}`;

          console.info(`👉 ${chalk.magenta(i + 1)} [${chalk.cyan(filename)}]`);
          console.info(chalk.dim(`${RAWDATA_PATH}/${username}/${filename}`));
          console.info(chalk.dim(cacheMorguePath));

          const wrappedSearchInGrep = grep.replace(new RegExp(search, 'ig'), (match) => {
            return chalk.bold(chalk.yellow(match));
          });
          console.info();
          console.debug(chalk.gray(wrappedSearchInGrep));
        });

        console.info(`🤖 ${searchResultMessage}`);
      },
    );
  }
}

async function parseMorgues({ spinner, allMorgueFileContent, hrStartTime }, morgueCallback, resultCallback) {
  const promiseSearchAllContent = allMorgueFileContent.map(async (morgue) => {
    spinner.text = `Parsing ${morgue.filename}`;
    spinner.render();

    const cacheMorguePath = `${CACHE_DIR}/${morgue.filename}`;
    return await morgueCallback(morgue, cacheMorguePath);
  });

  const results = await Promise.all(promiseSearchAllContent);
  const searchTime = Math.round(hrTimeUnit(process.hrtime(hrStartTime), 'ms'));

  const searchResultMessage = `Searched ${chalk.magenta(allMorgueFileContent.length)} morgue files (${chalk.dim(
    `${searchTime}ms`,
  )}).`;

  spinner.succeed(searchResultMessage);
  console.info();

  resultCallback({ results, searchTime });

  console.info(`🤖 ${searchResultMessage}`);
}

async function getUsernameMorgueContents(username, morgueFilenames, spinner) {
  spinner.text = `Gathering morgue files...`;
  spinner.render();

  const promiseAllMorgueFileContent = morgueFilenames.map(async (filename) => {
    const content = await cachedMorgue(username, filename, spinner);
    return { filename, content };
  });

  return await Promise.all(promiseAllMorgueFileContent);
}

async function cachedMorgue(username, morgueFilename, spinner) {
  const cacheMorguePath = `${CACHE_DIR}/${morgueFilename}`;

  if (!fs.existsSync(cacheMorguePath)) {
    spinner.text = `Fetching morgue files...`;
    spinner.render();

    const morgueUrl = `${RAWDATA_PATH}/${username}/${morgueFilename}`;
    const resp = await fetch(morgueUrl);
    const respText = await resp.text();

    fs.writeFileSync(cacheMorguePath, respText);
    return respText;
  }

  return fs.readFileSync(cacheMorguePath, { encoding: 'utf8', flag: 'r' });
}

async function getMorgueFilenames(username) {
  const resp = await fetch(`${RAWDATA_PATH}/${username}/?C=M;O=D`);

  if (resp.status === 404) {
    throw new Error('username not found');
  }

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

const hrTimeUnit = (hrTime, unit) => {
  switch (unit) {
    case 'milli':
    case 'millis':
    case 'ms':
      return hrTime[0] * 1e3 + hrTime[1] / 1e6;
    case 'micro':
      return hrTime[0] * 1e6 + hrTime[1] / 1e3;
    case 'nano':
    default:
      return hrTime[0] * 1e9 + hrTime[1];
  }
};

const toNumber = (value) => parseInt(value, 10);
const zeroPad = (value) => (value < 10 ? `0${value}` : value);

function secondsToTimeUnits(seconds) {
  const hourSeconds = 60 * 60;
  const minuteSeconds = 60;

  const hours = Math.floor(seconds / hourSeconds);
  // seconds % daySeconds % hourSeconds is seconds leftover for minutes
  // therefor seconds leftover for minutes / minuteSeconds = minutes
  const minutes = Math.floor((seconds % hourSeconds) / minuteSeconds);
  const remainderSeconds = (seconds % hourSeconds) % minuteSeconds;

  const totalHours = Math.floor(seconds / hourSeconds);

  const units = [];

  if (hours) {
    units.push(`${hours} hours`);
  }
  if (minutes) {
    units.push(`${minutes} minutes`);
  }
  if (remainderSeconds) {
    units.push(`${remainderSeconds} seconds`);
  }
  return units.join(' ');
}

async function parseMorgueFile(type, morgueText) {
  switch (type) {
    case '@time': {
      const match = morgueText.match(/Time: ([\d:]+)/);
      if (match) {
        const [, timeString] = match;
        const [hours, minutes, seconds] = timeString.split(':').map(toNumber);
        const timeSeconds = hours * 60 * 60 + minutes * 60 + seconds;
        return { timeSeconds };
      }

      return { timeSeconds: 0 };
    }
    default:
      return null;
  }
}

run();
