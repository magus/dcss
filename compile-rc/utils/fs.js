const fs = require('fs');

exports.read = (filename) => fs.readFileSync(filename).toString();
exports.append = (filename, content) => fs.appendFileSync(filename, content);
exports.write = (filename, content) => fs.writeFileSync(filename, content);
