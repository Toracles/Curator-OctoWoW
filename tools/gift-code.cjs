// SPDX-FileCopyrightText: 2026 CloudNine_Ex
// SPDX-License-Identifier: GPL-3.0-only

const crypto = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { parseArgs } = require('node:util');

const defaultKey = process.env.LOCALAPPDATA
  ? path.join(process.env.LOCALAPPDATA, 'Curator-OctoWoW', 'gift-signing.pem')
  : path.join(os.homedir(), '.curator-octowow', 'gift-signing.pem');
const limits = { zone: 99, dungeon: 99, raid: 99, rubies: 100000, xp: 500000 };

function count(value, maximum, label) {
  const n = Number(value);
  if (!/^\d+$/.test(value) || !Number.isSafeInteger(n) || n < 1 || n > maximum) {
    throw new Error(`${label} must be an integer between 1 and ${maximum}.`);
  }
  return n;
}

function publicLua(privateKey) {
  const jwk = crypto.createPublicKey(privateKey).export({ format: 'jwk' });
  const modulus = Buffer.from(jwk.n ?? '', 'base64url');
  if (jwk.kty !== 'RSA' || jwk.e !== 'Aw' || modulus.length !== 256) {
    throw new Error('Curator requires a 2048-bit RSA key with public exponent 3.');
  }
  const hex = modulus.toString('hex');
  const r2 = ((1n << 4096n) % BigInt('0x' + hex)).toString(16).padStart(512, '0');
  return '-- Public verification key for OctoWoW gift codes.\n'
    + 'ns.OCTO_GIFT_KEY = {\n'
    + `\tn = "${hex}",\n\tr2 = "${r2}",\n}\n`;
}

function issue(privateKey, options) {
  const to = options.to ?? '';
  const character = /^[\p{L}][\p{L}'’]*-[\p{L}\p{N}][\p{L}\p{N} .’'-]*$/u;
  if (Buffer.byteLength(to) > 80 || (!character.test(to) && !/^[a-f\d]{16}$/i.test(to))) {
    throw new Error('Give a recipient with --to Character-Realm or a 16-digit hexadecimal collection ID.');
  }
  const rewards = [];
  for (const [kind, maximum] of Object.entries(limits)) {
    if (options[kind] !== undefined) rewards.push(`${kind} ${count(options[kind], maximum, kind)}`);
  }
  const albums = new Set();
  for (const display of options.display ?? []) {
    const match = /^([A-Za-z0-9]+):(\d+)$/.exec(display);
    if (!match || albums.has(match[1])) throw new Error('Use --display ALBUM:COUNT once per album.');
    albums.add(match[1]);
    rewards.push(`displays ${match[1]} ${count(match[2], 20, 'display')}`);
  }
  if (rewards.length === 0) throw new Error('Include at least one reward.');

  const expires = Math.floor(Date.now() / 1000) + count(options.days ?? '30', 3650, 'days') * 86400;
  const lines = ['gift 1', 'id ' + crypto.randomBytes(12).toString('hex'), 'to ' + to, ...rewards, 'until ' + expires];
  if (options.note !== undefined) {
    const { note } = options;
    if (!note.trim() || Buffer.byteLength(note) > 160 || /[\x00-\x1f\x7f|]/.test(note)) {
      throw new Error('The note must be one line, with at most 160 UTF-8 bytes and no pipe character.');
    }
    lines.push('note ' + note);
  }

  const payload = Buffer.from(lines.join('\n'));
  const signature = crypto.sign('sha256', payload, { key: privateKey, padding: crypto.constants.RSA_PKCS1_PADDING });
  const code = `CG2.${payload.toString('base64url')}.${signature.toString('base64url')}`;
  if (code.length > 3000) throw new Error('The gift code exceeds the client limit of 3000 characters.');
  return code + '\n';
}

function main() {
  const [command, ...args] = process.argv.slice(2);
  const common = { key: { type: 'string', default: defaultKey } };
  if (command === 'init' || command === 'public') {
    const { values } = parseArgs({ args, options: common });
    if (command === 'init') {
      fs.mkdirSync(path.dirname(values.key), { recursive: true, mode: 0o700 });
      const { privateKey } = crypto.generateKeyPairSync('rsa', { modulusLength: 2048, publicExponent: 3 });
      fs.writeFileSync(values.key, privateKey.export({ type: 'pkcs8', format: 'pem' }), { flag: 'wx', mode: 0o600 });
      process.stdout.write(publicLua(privateKey));
      return;
    }
    process.stdout.write(publicLua(fs.readFileSync(values.key)));
    return;
  }
  if (command !== 'issue') {
    throw new Error('Use init, public or issue. Example: node tools/gift-code.cjs issue --to "Daio-N\'Zoth" --zone 1 --rubies 100');
  }
  const { values } = parseArgs({ args, options: {
    ...common,
    to: { type: 'string' },
    days: { type: 'string' },
    note: { type: 'string' },
    display: { type: 'string', multiple: true },
    ...Object.fromEntries(Object.keys(limits).map(kind => [kind, { type: 'string' }])),
  } });
  const key = fs.readFileSync(values.key);
  publicLua(key);
  process.stdout.write(issue(key, values));
}

try {
  main();
} catch (error) {
  process.stderr.write(error.message + '\n');
  process.exitCode = 1;
}
