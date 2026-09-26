import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { existsSync } from 'fs';
import { execSync } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
// The dev server in AI Studio must always listen on port 3000.
// Cloud Run sets PORT=8080 for the outer reverse proxy (nginx), which forwards to 3000.
const PORT = 3000;
const buildDir = path.resolve(__dirname, 'build/web');

// Ensure Flutter Web build exists
if (!existsSync(path.join(buildDir, 'index.html'))) {
  console.log('Initial Flutter Web build starting...');
  execSync('flutter build web --release', { stdio: 'inherit' });
}

// Serve Flutter Web static assets
app.use(
  express.static(buildDir, {
    setHeaders: (res, filePath) => {
      if (filePath.endsWith('.wasm')) {
        res.setHeader('Content-Type', 'application/wasm');
      }
    },
  })
);

// Fallback all routes to Flutter Web index.html for client-side routing
app.get('*', (req, res) => {
  res.sendFile(path.join(buildDir, 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Flutter Web app listening on http://0.0.0.0:${PORT}`);
});
