const fs = require('fs');

exports.read = (filename) => fs.readFileSync(filename).toString();
exports.write = (filename, content) => fs.writeFileSync(filename, content);
