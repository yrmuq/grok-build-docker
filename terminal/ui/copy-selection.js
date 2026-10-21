/* grok-copy-selection: keep a visible selection and copy it on mouseup.
   Right-click is swallowed so tmux/browser menus do not replace the shell menu. */
(function () {
  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).catch(function () {});
      return;
    }
    const area = document.createElement('textarea');
    area.value = text;
    area.setAttribute('readonly', '');
    area.style.position = 'fixed';
    area.style.top = '0';
    area.style.left = '0';
    area.style.opacity = '0';
    document.body.appendChild(area);
    area.focus();
    area.select();
    try { document.execCommand('copy'); } catch (err) {}
    area.remove();
  }

  function hook(term) {
    if (!term || term.__grokCopy) return;
    term.__grokCopy = true;
    const theme = term.options.theme || {};
    if (theme.selectionBackground && !theme.selectionInactiveBackground) {
      term.options.theme = Object.assign({}, theme, {
        selectionInactiveBackground: theme.selectionBackground
      });
    }
    const el = term.element;
    if (!el) return;
    el.addEventListener('mouseup', function () {
      const text = term.getSelection();
      if (text) copyText(text);
      term.focus();
    });
    el.addEventListener('contextmenu', function (event) {
      event.preventDefault();
      const text = term.getSelection();
      if (text) copyText(text);
      term.focus();
    });
  }

  function install() {
    if (typeof Terminal === 'undefined' || !Terminal.prototype) return false;
    const original = Terminal.prototype.open;
    if (original.__grokCopy) return true;
    function wrappedOpen() {
      const result = original.apply(this, arguments);
      hook(this);
      return result;
    }
    wrappedOpen.__grokCopy = true;
    Terminal.prototype.open = wrappedOpen;
    return true;
  }

  if (!install()) {
    const timer = setInterval(function () {
      if (install()) clearInterval(timer);
    }, 20);
  }
})();
