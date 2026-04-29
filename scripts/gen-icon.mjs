// Generates AppIcon-1024.png — Playa "Hot" gradient square with white "P" wordmark.
// Run: node scripts/gen-icon.mjs
import { writeFileSync, mkdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import zlib from 'node:zlib';

const __dirname = dirname(fileURLToPath(import.meta.url));
const outDir = resolve(__dirname, '..', 'Playa', 'Assets.xcassets', 'AppIcon.appiconset');
mkdirSync(outDir, { recursive: true });

const SIZE = 1024;
const HOT       = [0xFF, 0x2D, 0x6C]; // #FF2D6C
const HOT_DEEP  = [0xD8, 0x1C, 0x5A]; // #D81C5A
const WHITE     = [255, 255, 255];

function lerp(a, b, t) {
  return [
    Math.round(a[0] + (b[0] - a[0]) * t),
    Math.round(a[1] + (b[1] - a[1]) * t),
    Math.round(a[2] + (b[2] - a[2]) * t),
  ];
}

function pngBuffer(width, height, drawPixel) {
  const channels = 3;
  const bytesPerRow = width * channels + 1;
  const raw = Buffer.alloc(bytesPerRow * height);
  for (let y = 0; y < height; y++) {
    raw[y * bytesPerRow] = 0;
    for (let x = 0; x < width; x++) {
      const px = drawPixel(x, y);
      const o = y * bytesPerRow + 1 + x * channels;
      raw[o] = px[0]; raw[o + 1] = px[1]; raw[o + 2] = px[2];
    }
  }
  const idat = zlib.deflateSync(raw, { level: 9 });
  const sig = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; ihdr[9] = 2; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  return Buffer.concat([sig, chunk('IHDR', ihdr), chunk('IDAT', idat), chunk('IEND', Buffer.alloc(0))]);
}

function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length, 0);
  const typeBuf = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 0);
  return Buffer.concat([len, typeBuf, data, crc]);
}

const CRC = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

// "P" glyph: vertical stem + a hollow upper bowl built from a thick ring.
function inPGlyph(x, y, x0, y0, x1, y1, thick) {
  if (x < x0 || x > x1 || y < y0 || y > y1) return false;
  const w = x1 - x0;
  const h = y1 - y0;
  const t = thick;

  // Vertical stem on the left
  if (x >= x0 && x <= x0 + t && y >= y0 && y <= y1) return true;

  // Upper bowl: ring centered on (cx, cy)
  const bowlTop = y0;
  const bowlBottom = y0 + h * 0.55;
  const cx = x0 + (x1 - x0) * 0.55;
  const cy = (bowlTop + bowlBottom) / 2;
  const rOuter = Math.min((x1 - x0) * 0.45, (bowlBottom - bowlTop) / 2);
  const rInner = rOuter - t;
  const dx = x - cx, dy = y - cy;
  const r = Math.sqrt(dx * dx + dy * dy);
  if (r <= rOuter && r >= rInner && y <= bowlBottom) return true;

  // Connect ring to stem
  if (rectFilled(x, y, x0, bowlTop, cx, bowlTop + t)) return true;
  if (rectFilled(x, y, x0, bowlBottom - t, cx, bowlBottom)) return true;

  return false;
}

function rectFilled(x, y, x0, y0, x1, y1) {
  return x >= x0 && x <= x1 && y >= y0 && y <= y1;
}

const cx = SIZE / 2, cy = SIZE / 2;
const glyphHeight = SIZE * 0.55;
const glyphThick = Math.round(SIZE * 0.10);
const glyphWidth = glyphHeight * 0.75;
const gx0 = cx - glyphWidth / 2;
const gx1 = cx + glyphWidth / 2;
const gy0 = cy - glyphHeight / 2;
const gy1 = cy + glyphHeight / 2;

const buf = pngBuffer(SIZE, SIZE, (x, y) => {
  // Diagonal gradient from top-left HOT to bottom-right HOT_DEEP
  const t = (x + y) / (SIZE * 2);
  const bg = lerp(HOT, HOT_DEEP, t);

  if (inPGlyph(x, y, gx0, gy0, gx1, gy1, glyphThick)) {
    return WHITE;
  }
  return bg;
});

writeFileSync(resolve(outDir, 'AppIcon-1024.png'), buf);
console.log('wrote AppIcon-1024.png (' + buf.length + ' bytes)');
