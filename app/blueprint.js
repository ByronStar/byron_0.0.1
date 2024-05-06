const fs = require('fs')
const zlib = require('zlib');

const readData = (file) => {
    return new Promise((resolve, reject) => {
        fs.readFile(file, 'utf-8', (error, contents) => {
            if (error) {
                reject(error)
            } else {
                let bp = zlib.inflateSync(Buffer.from(contents.substring(1), 'base64')).toString();
                // console.log(bp);
                resolve(JSON.parse(bp))
            }
        })
    })
}

if (process.argv[2])  {
    readData(process.argv[2]).then(bp => {
        console.log(JSON.stringify(bp, null, 2))
    })
} else {
    let input = "Hellow world";

    let deflated = zlib.deflateSync(input).toString('base64');
    let inflated = zlib.inflateSync(Buffer.from(deflated, 'base64')).toString();
    
    console.log(inflated);    
}