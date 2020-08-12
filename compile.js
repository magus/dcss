const { execSync } = require("child_process");
const FSUtils = require("./utils/fs");
const PartsUtils = require("./utils/parts");

const TEMPLATE_FILENAME = "_template.rc";
const OUTPUT_FILENAME = "output/magus.rc";

// ensure output directory
execSync(`rm -rf $(dirname ${OUTPUT_FILENAME})`);
execSync(`mkdir -p $(dirname ${OUTPUT_FILENAME})`);

console.info(`Hydrating ${TEMPLATE_FILENAME} parts...`);

let OUTPUT_RC = FSUtils.read(TEMPLATE_FILENAME);

// Replace `##Header Content` with a formatted header containing "Content"
OUTPUT_RC = PartsUtils.RunRegex(/\#\#Header (.*)/g, OUTPUT_RC, (header) => {
  return PartsUtils.Header(header);
});

// Replace `{{Filename.ext}}` with the file content using PartsUtil.ContentFormatter
OUTPUT_RC = PartsUtils.RunRegex(/{{(.*)}}/g, OUTPUT_RC, (filename) => {
  return PartsUtils.ContentFormatter(
    filename,
    FSUtils.read(`parts/${filename}`)
  );
});

console.info("All parts successfully hydrated.");

FSUtils.write(OUTPUT_FILENAME, OUTPUT_RC);
