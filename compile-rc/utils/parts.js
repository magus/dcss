const luamin = require('luamin');

function HeaderInternal(header, withMsg, withTime) {
  return `
##
## ${header}
################################################################################################
`.trim();
}

function Header(args) {
  const header = args.join(' ');
  return HeaderInternal(header);
}

exports.Header = Header;

function Begin(args) {
  return `
##
## BEGIN
################################################################################################
: rc_msg("Initializing magus.rc ...")
`.trim();
}

exports.Begin = Begin;

function End(args) {
  return `
##
## END
################################################################################################
: rc_scs("Successfully initialized magus.rc [{{VERSION}}]")
`.trim();
}

exports.End = End;

const EXTENSION_REGEX = /\.(.*)$/;

exports.ContentFormatter = function ContentFormatter(filename, content, minifyLua = false) {
  const [, ext] = filename.match(EXTENSION_REGEX);
  let formattedContent;
  switch (ext) {
    // lua content must be wrapped in braces
    case 'lua':
      const luaContent = minifyLua ? luamin.minify(content) + '\n' : content;
      formattedContent = `{\n${luaContent}}`;
      break;
    // default and rc files just insert plain text
    case 'rc':
    default:
      formattedContent = content;
  }

  return [HeaderInternal(filename, true /* withMsg */), formattedContent].join('\n');
};

exports.RunRegex = function RunRegex(regex, input, replacer) {
  // copy input to string output
  // if we do not copy here the regex will skip weirdly
  // See https://codesandbox.io/s/infallible-moser-v2m6s?file=/src/index.js
  let output = input;

  while (true) {
    const match = regex.exec(input);

    // regex will cycle when all matches have been found
    // match will be `null` and we can safely break out and exit
    if (match === null) {
      break;
    }

    const [placeholder, headerType, args] = match;
    const splitArgs = typeof args === 'string' ? args.trim().split(' ') : [];

    // console.debug({ placeholder, headerType, splitArgs });

    const fill = replacer(headerType, splitArgs);

    if (typeof fill === 'string') {
      output = output.replace(placeholder, fill.trim());
    }
  }

  return output;
};
