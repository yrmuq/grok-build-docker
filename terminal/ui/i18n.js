(function (root) {
  function placeholders(text) {
    return (String(text || '').match(/\{[A-Za-z0-9_]+\}/g) || []).sort().join('\n');
  }

  function parseCatalog(text) {
    const catalog = { code: '', name: '', entries: {} };
    String(text || '').replace(/^\uFEFF/, '').split(/\r?\n/).forEach(function (line) {
      const trimmed = line.trim();
      if (!trimmed) return;
      if (trimmed.charAt(0) === ';') {
        const code = trimmed.match(/^;\s*code\s*=\s*(.+)$/i);
        const name = trimmed.match(/^;\s*name\s*=\s*(.+)$/i);
        if (code) catalog.code = code[1].trim();
        if (name) catalog.name = name[1].trim();
        return;
      }
      const match = trimmed.match(/^(\d+)\s*=\s*(.*?)\s*=\s*(.*)$/);
      if (!match) return;
      catalog.entries[match[1]] = { en: match[2], text: match[3] };
    });
    return catalog;
  }

  function translate(catalog, id, vars) {
    const entry = catalog && catalog.entries && catalog.entries[String(id)];
    if (!entry) return '';
    let text = entry.text;
    if (!text || placeholders(text) !== placeholders(entry.en)) text = entry.en;
    if (vars) {
      Object.keys(vars).forEach(function (key) {
        text = text.split('{' + key + '}').join(String(vars[key]));
      });
    }
    return text;
  }

  const api = { parseCatalog: parseCatalog, translate: translate, placeholders: placeholders };
  root.GrokI18n = api;
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
})(typeof globalThis !== 'undefined' ? globalThis : this);
