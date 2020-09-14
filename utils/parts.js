const luamin = require("luamin");

function HeaderInternal(header, withMsg, withTime) {
  return `
##
## ${header}
################################################################################################
${withMsg ? `: rc_msg(" += ${header}")` : ""}
`.trim();
}

function Header(args) {
  const header = args.join(" ");
  return HeaderInternal(header);
}

exports.Header = Header;

function Begin(args) {
  const version = args.join(" ");

  return `
##
## BEGIN
################################################################################################
: rc_msg("Initializing magus.rc [v${version}.${Date.now()}] ...")
`.trim();
}

exports.Begin = Begin;

function End() {
  return `
##
## END
################################################################################################
: rc_scs("Successfully initialized magus.rc!")
`.trim();
}

exports.End = End;

const EXTENSION_REGEX = /\.(.*)$/;

exports.ContentFormatter = function ContentFormatter(
  filename,
  content,
  minifyLua = false
) {
  const [, ext] = filename.match(EXTENSION_REGEX);
  let formattedContent;
  switch (ext) {
    // lua content must be wrapped in braces
    case "lua":
      const luaContent = minifyLua ? luamin.minify(content) + "\n" : content;
      formattedContent = `{\n${luaContent}}`;
      break;
    // default and rc files just insert plain text
    case "rc":
    default:
      formattedContent = content;
  }

  return [HeaderInternal(filename, true /* withMsg */), formattedContent].join(
    "\n"
  );
};

exports.RunRegex = function RunRegex(regex, output, replacer) {
  while (true) {
    const match = regex.exec(output);

    // regex will cycle when all matches have been found
    // match will be `null` and we can safely break out and exit
    if (match === null) break;

    const [placeholder, headerType, args] = match;
    const splitArgs = typeof args === "string" ? args.trim().split(" ") : [];

    // console.debug({ placeholder, headerType, splitArgs });

    const fill = replacer(headerType, splitArgs);

    output = output.replace(placeholder, fill.trim());
  }

  return output;
};
