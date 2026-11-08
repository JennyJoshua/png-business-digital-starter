// Tiny local preview server (testing only). Usage: node scripts/serve.mjs dist [port]
import http from 'node:http'; import fs from 'node:fs'; import path from 'node:path';
const dir = path.resolve(process.argv[2] || 'dist'); const port = +process.argv[3] || 8080;
const types = { '.html': 'text/html', '.css': 'text/css', '.svg': 'image/svg+xml', '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg', '.webp': 'image/webp' };
http.createServer((req, res) => {
  let f = path.join(dir, decodeURIComponent(new URL(req.url, 'http://x').pathname)); if (f.endsWith(path.sep)) f += 'index.html';
  if (!f.startsWith(dir) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); return res.end('Not found'); }
  res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream' }); fs.createReadStream(f).pipe(res);
}).listen(port, () => console.log(`Preview: http://localhost:${port}`));
