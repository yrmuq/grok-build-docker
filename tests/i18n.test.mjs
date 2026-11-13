import { createRequire } from 'node:module';
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const require = createRequire(import.meta.url);
const { parseCatalog, translate, placeholders } = require('../terminal/ui/i18n.js');

test('falls back when the translation drops a placeholder', () => {
  const catalog = parseCatalog('9 = Close {name} = Закрыть\n');
  assert.equal(translate(catalog, 9, { name: 'chat0' }), 'Close chat0');
});

test('uses the translation when placeholders match', () => {
  const catalog = parseCatalog('9 = Close {name} = Закрыть {name}\n');
  assert.equal(translate(catalog, 9, { name: 'chat0' }), 'Закрыть chat0');
});

test('English and Russian catalogs share ids and placeholders', () => {
  const en = parseCatalog(readFileSync(new URL('../languages/English.ini', import.meta.url), 'utf8'));
  const ru = parseCatalog(readFileSync(new URL('../languages/Russian.ini', import.meta.url), 'utf8'));
  assert.equal(en.code, 'en');
  assert.equal(ru.code, 'ru');
  const ids = Object.keys(en.entries).sort();
  assert.deepEqual(Object.keys(ru.entries).sort(), ids);
  for (const id of ids) {
    assert.equal(placeholders(ru.entries[id].en), placeholders(en.entries[id].en));
    assert.equal(placeholders(ru.entries[id].text), placeholders(en.entries[id].en));
  }
});
