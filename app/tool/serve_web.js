// Serves build/web on every network interface so a phone on the same Wi-Fi can open it.
//   node tool/serve_web.js [port]
// Phone  -> http://<this PC's IPv4>:<port>  (compact / mobile layout)
// Laptop -> http://localhost:<port>         (expanded / desktop layout)
const http = require('http'), fs = require('fs'), path = require('path'), os = require('os');
const root = path.join(__dirname, '..', 'build', 'web');
const port = Number(process.argv[2] || 8081);
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.css': 'text/css', '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.svg': 'image/svg+xml', '.ico': 'image/x-icon', '.wasm': 'application/wasm', '.ttf': 'font/ttf', '.otf': 'font/otf', '.woff2': 'font/woff2', '.woff': 'font/woff', '.txt': 'text/plain', '.map': 'application/json' };
http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  let f = path.join(root, p);
  if (!f.startsWith(root)) { res.writeHead(403); return res.end(); }
  if (!fs.existsSync(f) || fs.statSync(f).isDirectory()) f = path.join(root, 'index.html'); // SPA fallback for go_router paths
  res.writeHead(200, { 'content-type': types[path.extname(f).toLowerCase()] || 'application/octet-stream', 'cache-control': 'no-store' });
  fs.createReadStream(f).pipe(res);
}).listen(port, '0.0.0.0', () => {
  console.log('Laptop: http://localhost:' + port);
  Object.values(os.networkInterfaces()).flat().filter(i => i.family === 'IPv4' && !i.internal).forEach(i => console.log('Phone:  http://' + i.address + ':' + port));
});
