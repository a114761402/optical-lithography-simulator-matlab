import {cp, mkdir, readFile, rm, writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {build} from 'esbuild';

const root=resolve(import.meta.dirname,'..');
const output=resolve(root,'ios-web');
await rm(output,{recursive:true,force:true});
await cp(resolve(root,'dist'),output,{recursive:true});
// This older raw calculation is superseded by the five verified gzip presets.
await rm(resolve(output,'data/default-wave-circular-fine-v4.json'),{force:true});
await mkdir(output,{recursive:true});
await build({entryPoints:[resolve(root,'scripts/native-bridge.js')],outfile:resolve(output,'native-bridge.js'),bundle:true,format:'esm',platform:'browser',target:'safari18',minify:true});
const htmlPath=resolve(output,'index.html');
const html=await readFile(htmlPath,'utf8');
const entry=html.match(/<script type="module" src="app\.js(?:\?[^\"]*)?"><\/script>/)?.[0];
if(!entry)throw Error('Cannot locate the web application entry point.');
await writeFile(htmlPath,html.replace(entry,'<script type="module" src="native-bridge.js"></script>\n  '+entry));
// Full sync also clears the generated native copy so obsolete bundled files
// and filesystem conflict copies cannot survive later packaging.
if(process.argv.includes('--sync'))await rm(resolve(root,'ios/App/App/public'),{recursive:true,force:true});
console.log('Prepared offline iPhone assets in ios-web/.');
