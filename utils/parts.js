function Header(header) {
  return `##
## ${header}
################################################################################################`;
}

exports.Header = Header;

const EXTENSION_REGEX = /\.(.*)$/;

exports.ContentFormatter = function ContentFormatter(filename, content) {
  const [, ext] = filename.match(EXTENSION_REGEX);
  let formattedContent;
  switch (ext) {
    // lua content must be wrapped in braces
    case "lua":
      formattedContent = `{\n${content}}`;
      break;
    // default and rc files just insert plain text
    case "rc":
    default:
      formattedContent = content;
  }

  return [Header(filename), formattedContent].join("\n");
};

exports.RunRegex = function RunRegex(regex, output, replacer) {
  while (true) {
    const match = regex.exec(output);

    // regex will cycle when all matches have been found
    // match will be `null` and we can safely break out and exit
    if (match === null) break;

    const [placeholder, content] = match;
    // console.debug({ placeholder, content });

    const fill = replacer(content);

    output = output.replace(placeholder, fill);
  }

  return output;
};
