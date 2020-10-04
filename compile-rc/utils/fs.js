const fs = require('fs');

exports.read = (filename) => fs.readFileSync(filename).toString();
exports.readJSON = (filename) => {
  const content = fs.readFileSync(filename).toString();
  try {
    const json = JSON.parse(content);
    return json;
  } catch (err) {
    return null;
  }
};
exports.append = (filename, content) => fs.appendFileSync(filename, content);
exports.write = (filename, content) => fs.writeFileSync(filename, content);
