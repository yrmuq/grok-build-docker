/* grok-copy-selection: Ctrl+C copies the selection and does not also interrupt the shell.
   The browser context menu stays available for Copy and Paste. */
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
    term.attachCustomKeyEventHandler(function (event) {
      if (event.type !== 'keydown') return true;
      const copy = event.ctrlKey && !event.shiftKey && !event.altKey && !event.metaKey
        && (event.key === 'c' || event.key === 'C');
      if (!copy) return true;
      const text = term.getSelection();
      if (!text) return true;
      copyText(text);
      term.focus();
      return false;
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
