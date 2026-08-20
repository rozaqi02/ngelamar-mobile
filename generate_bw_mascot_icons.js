const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

// Minimal pure Node.js PNG encoder using built-in zlib
function createPNG(width, height, getPixelRGBA) {
  // CRC32 table
  const crcTable = [];
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) {
      c = (c & 1) ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
    }
    crcTable[n] = c;
  }

  function crc32(buf) {
    let crc = 0xffffffff;
    for (let i = 0; i < buf.length; i++) {
      crc = (crc >>> 8) ^ crcTable[(crc ^ buf[i]) & 0xff];
    }
    return (crc ^ 0xffffffff) >>> 0;
  }

  function makeChunk(type, data) {
    const len = data.length;
    const buf = Buffer.alloc(12 + len);
    buf.writeUInt32BE(len, 0);
    buf.write(type, 4, 4, 'ascii');
    data.copy(buf, 8);
    const chunkCrc = crc32(buf.subarray(4, 8 + len));
    buf.writeUInt32BE(chunkCrc, 8 + len);
    return buf;
  }

  // Header: Signature
  const signature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

  // IHDR
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // 8 bit depth
  ihdr[9] = 6; // RGBA
  ihdr[10] = 0; // compression
  ihdr[11] = 0; // filter
  ihdr[12] = 0; // interlace
  const ihdrChunk = makeChunk('IHDR', ihdr);

  // Raw image data with 0 filter byte per row
  const rawRowLen = 1 + width * 4;
  const rawData = Buffer.alloc(height * rawRowLen);

  for (let y = 0; y < height; y++) {
    const rowOffset = y * rawRowLen;
    rawData[rowOffset] = 0; // Filter: None
    for (let x = 0; x < width; x++) {
      const [r, g, b, a] = getPixelRGBA(x, y, width, height);
      const pxOffset = rowOffset + 1 + x * 4;
      rawData[pxOffset] = r;
      rawData[pxOffset + 1] = g;
      rawData[pxOffset + 2] = b;
      rawData[pxOffset + 3] = a;
    }
  }

  const compressed = zlib.deflateSync(rawData);
  const idatChunk = makeChunk('IDAT', compressed);
  const iendChunk = makeChunk('IEND', Buffer.alloc(0));

  return Buffer.concat([signature, ihdrChunk, idatChunk, iendChunk]);
}

// Draw the Retro Running Envelope Mascot in Black & White on Dark Circular Badge
function getMascotPixel(x, y, width, height) {
  // Normalize coords to [-1.0, 1.0]
  const nx = (x / width) * 2 - 1;
  const ny = (y / height) * 2 - 1;

  // Background: Jet Black Rounded / Circular Surface (#121214)
  const distCenter = Math.sqrt(nx * nx + ny * ny);
  if (distCenter > 0.96) {
    return [0, 0, 0, 0]; // Transparent outer border for rounded launcher
  }

  // Deep dark background
  let r = 18, g = 18, b = 20, a = 255;

  // Outer circular border (White ring at edge)
  if (distCenter > 0.88 && distCenter <= 0.94) {
    return [255, 255, 255, 255];
  }

  // Envelope Coordinates (Mascot Center: slightly tilted at ~ -8 deg)
  // Translate & rotate
  const cx = nx + 0.05;
  const cy = ny + 0.05;
  const angle = 0.12; // slight tilt
  const rx = cx * Math.cos(angle) - cy * Math.sin(angle);
  const ry = cx * Math.sin(angle) + cy * Math.cos(angle);

  // 1. Envelope Body (Rect: rx from -0.42 to 0.42, ry from -0.30 to 0.28)
  const inEnvBody = (rx >= -0.42 && rx <= 0.42 && ry >= -0.30 && ry <= 0.28);
  const inEnvBorder = inEnvBody && (rx <= -0.38 || rx >= 0.38 || ry <= -0.26 || ry >= 0.24);

  // V-Flap lines (from (-0.42, -0.30) to (0, 0.02) and from (0.42, -0.30) to (0, 0.02))
  const leftFlapDist = Math.abs((0.02 - (-0.30)) * rx - (0 - (-0.42)) * ry + (-0.42 * 0.02 - 0 * (-0.30))) / Math.sqrt(0.32 * 0.32 + 0.42 * 0.42);
  const rightFlapDist = Math.abs((0.02 - (-0.30)) * rx - (0 - 0.42) * ry + (0.42 * 0.02 - 0 * (-0.30))) / Math.sqrt(0.32 * 0.32 + 0.42 * 0.42);
  const onFlap = (ry <= 0.04 && rx >= -0.42 && rx <= 0.42 && (leftFlapDist < 0.032 || rightFlapDist < 0.032));

  // 2. Eyes (Two big googly cartoon eyes on upper part of envelope)
  // Left eye center: (-0.14, -0.10), radius: 0.13
  const dLeftEye = Math.hypot(rx - (-0.14), ry - (-0.10));
  // Right eye center: (0.16, -0.09), radius: 0.14
  const dRightEye = Math.hypot(rx - 0.16, ry - (-0.09));

  // Eye Pupils
  const dLeftPupil = Math.hypot(rx - (-0.11), ry - (-0.09));
  const dRightPupil = Math.hypot(rx - 0.19, ry - (-0.08));

  // 3. Toothy Mouth Grid (Smile below eyes)
  // Mouth bounds: rx in [-0.22, 0.22], ry in [0.06, 0.22]
  const mouthCurveY = 0.06 + (rx * rx) * 1.5;
  const inMouth = (rx >= -0.22 && rx <= 0.22 && ry >= mouthCurveY && ry <= 0.22);
  const inMouthBorder = inMouth && (ry <= mouthCurveY + 0.03 || ry >= 0.19 || rx <= -0.19 || rx >= 0.19);
  const isTeethLine = inMouth && (Math.abs(ry - 0.14) < 0.02 || Math.abs(rx - (-0.08)) < 0.02 || Math.abs(rx - 0.06) < 0.02);

  // 4. Punching Fist / Arm (Right arm: rx from 0.42 to 0.65, ry from -0.12 to 0.02)
  const dFist = Math.hypot(rx - 0.62, ry - (-0.04));
  const inArm = (rx >= 0.38 && rx <= 0.62 && Math.abs(ry - (-0.04) - (rx - 0.5) * 0.4) < 0.05);

  // 5. Left Back Arm (Swinging back: rx from -0.60 to -0.42, ry from -0.05 to 0.10)
  const dLeftFist = Math.hypot(rx - (-0.56), ry - 0.08);
  const inLeftArm = (rx >= -0.58 && rx <= -0.38 && Math.abs(ry - 0.05 + (rx + 0.48) * 0.3) < 0.045);

  // 6. Running Legs & Sneakers
  // Front Leg: rx from 0.18 to 0.42, ry from 0.28 to 0.56
  const dFrontShoe = Math.hypot(rx - 0.42, ry - 0.52);
  const inFrontLeg = (rx >= 0.16 && rx <= 0.42 && Math.abs(ry - 0.28 - (rx - 0.18) * 1.0) < 0.05);
  // Back Leg: rx from -0.36 to -0.20, ry from 0.28 to 0.58
  const dBackShoe = Math.hypot(rx - (-0.36), ry - 0.56);
  const inBackLeg = (rx >= -0.38 && rx <= -0.16 && Math.abs(ry - 0.28 + (rx + 0.20) * 1.2) < 0.05);

  // 7. Speed Lines (Behind mascot on the left)
  const inSpeedLine1 = (nx >= -0.82 && nx <= -0.55 && Math.abs(ny - (-0.18)) < 0.025);
  const inSpeedLine2 = (nx >= -0.86 && nx <= -0.62 && Math.abs(ny - 0.02) < 0.025);
  const inSpeedLine3 = (nx >= -0.78 && nx <= -0.52 && Math.abs(ny - 0.22) < 0.025);

  // Composite drawing logic
  if (inSpeedLine1 || inSpeedLine2 || inSpeedLine3) {
    return [255, 255, 255, 220]; // White speed lines
  }

  // Draw Fist & Arm
  if (dFist < 0.09 || dLeftFist < 0.08 || inArm || inLeftArm) {
    if (dFist < 0.06 || dLeftFist < 0.055) {
      return [255, 255, 255, 255]; // White fist
    }
    return [0, 0, 0, 255]; // Black fist outline
  }

  // Draw Legs & Shoes
  if (dFrontShoe < 0.10 || dBackShoe < 0.10 || inFrontLeg || inBackLeg) {
    if (dFrontShoe < 0.07 || dBackShoe < 0.07) {
      return [255, 255, 255, 255]; // White shoe
    }
    return [0, 0, 0, 255]; // Black leg/shoe outline
  }

  // Draw Eyes
  if (dLeftPupil < 0.055 || dRightPupil < 0.06) {
    return [18, 18, 20, 255]; // Black pupil
  }
  if (dLeftEye < 0.13 || dRightEye < 0.14) {
    if (dLeftEye >= 0.105 || dRightEye >= 0.115) {
      return [18, 18, 20, 255]; // Black eye outline
    }
    return [255, 255, 255, 255]; // White eye sclera
  }

  // Draw Mouth
  if (inMouth) {
    if (inMouthBorder || isTeethLine) {
      return [18, 18, 20, 255]; // Black mouth line & teeth
    }
    return [255, 255, 255, 255]; // White teeth
  }

  // Draw Envelope Flap & Body
  if (inEnvBody) {
    if (inEnvBorder || onFlap) {
      return [18, 18, 20, 255]; // Black envelope stroke & flap
    }
    return [255, 255, 255, 255]; // Crisp white envelope body
  }

  return [r, g, b, a];
}

// Generate all sizes
const targets = [
  { dir: 'android/app/src/main/res/mipmap-mdpi', file: 'ic_launcher.png', size: 48 },
  { dir: 'android/app/src/main/res/mipmap-hdpi', file: 'ic_launcher.png', size: 72 },
  { dir: 'android/app/src/main/res/mipmap-xhdpi', file: 'ic_launcher.png', size: 96 },
  { dir: 'android/app/src/main/res/mipmap-xxhdpi', file: 'ic_launcher.png', size: 144 },
  { dir: 'android/app/src/main/res/mipmap-xxxhdpi', file: 'ic_launcher.png', size: 192 },
  { dir: 'ios/Runner/Assets.xcassets/AppIcon.appiconset', file: 'Icon-App-1024x1024@1x.png', size: 1024 },
  { dir: 'web/icons', file: 'Icon-192.png', size: 192 },
  { dir: 'web/icons', file: 'Icon-512.png', size: 512 },
  { dir: 'web/icons', file: 'Icon-maskable-192.png', size: 192 },
  { dir: 'web/icons', file: 'Icon-maskable-512.png', size: 512 },
];

for (const t of targets) {
  const fullDir = path.resolve(__dirname, t.dir);
  if (!fs.existsSync(fullDir)) {
    fs.mkdirSync(fullDir, { recursive: true });
  }
  const fullPath = path.join(fullDir, t.file);
  console.log(`Generating B&W Mascot Icon: ${t.size}x${t.size} -> ${fullPath}`);
  const pngData = createPNG(t.size, t.size, getMascotPixel);
  fs.writeFileSync(fullPath, pngData);
}

console.log('All black & white mascot launcher icons successfully generated!');
