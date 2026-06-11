const fs = require('fs');
const path = require('path');

function findFiles(dir, fileList = []) {
  if (!fs.existsSync(dir)) return fileList;
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const filePath = path.join(dir, file);
    if (fs.statSync(filePath).isDirectory()) {
      findFiles(filePath, fileList);
    } else if (filePath.endsWith('.js')) {
      fileList.push(filePath);
    }
  }
  return fileList;
}

const dirsToPatch = [
  path.join(__dirname, 'node_modules/react-native/Libraries/Animated'),
  path.join(__dirname, 'node_modules/react-native/src/private/devsupport')
];

let files = [];
for (const dir of dirsToPatch) {
  files = files.concat(findFiles(dir));
}

let patchCount = 0;
for (const file of files) {
  let content = fs.readFileSync(file, 'utf8');
  // Replace #fieldName with _fieldName
  const patched = content.replace(/(?<!\w)#([a-zA-Z_]\w*)/g, '_$1');
  if (content !== patched) {
    fs.writeFileSync(file, patched, 'utf8');
    patchCount++;
    console.log(`Patched ${file}`);
  }
}
console.log(`Patched ${patchCount} files.`);
