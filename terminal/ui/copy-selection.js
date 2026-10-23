/* grok-copy-selection: a drag selects text even while Grok has mouse reporting on.
   Releasing the button copies the text, clears the highlight, and shows "copied".
   A plain click still goes to Grok. */
(function () {
  let banner;
  let bannerTimer;

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

  function showCopied(term) {
    const theme = (term && term.options && term.options.theme) || {};
    const background = theme.background || '#141414';
    const foreground = theme.foreground || '#e1e1e1';
    if (!banner) {
      banner = document.createElement('div');
      banner.textContent = 'copied';
      document.body.appendChild(banner);
    }
    banner.style.cssText = [
      'position:fixed',
      'left:12px',
      'bottom:12px',
      'z-index:40',
      'padding:6px 10px',
      'border-radius:6px',
      'border:1px solid ' + foreground,
      'background:' + background,
      'color:' + foreground,
      'font:13px/1.2 ui-monospace, SFMono-Regular, Menlo, monospace',
      'pointer-events:none',
      'opacity:1',
      'transition:opacity .25s linear'
    ].join(';');
    clearTimeout(bannerTimer);
    bannerTimer = setTimeout(function () {
      if (banner) banner.style.opacity = '0';
    }, 900);
  }

  const replayed = new WeakSet();

  function mouseInit(type, x, y, shift, detail) {
    const event = new MouseEvent(type, {
      bubbles: true,
      cancelable: true,
      view: window,
      button: 0,
      buttons: type === 'mousedown' ? 1 : 0,
      clientX: x,
      clientY: y,
      shiftKey: !!shift,
      detail: detail || 1
    });
    replayed.add(event);
    return event;
  }

  function attachMouseCopy(term) {
    const root = term.element;
    if (!root || root.__grokMouseCopy) return;
    const screen = root.querySelector('.xterm-screen');
    if (!screen) return;
    root.__grokMouseCopy = true;

    screen.addEventListener('mousedown', function (event) {
      if (replayed.has(event)) return;
      if (event.button !== 0 || event.shiftKey || event.ctrlKey || event.altKey || event.metaKey) return;
      event.stopImmediatePropagation();
      event.preventDefault();

      const startX = event.clientX;
      const startY = event.clientY;
      const word = event.detail >= 2;
      let drag = word;
      if (word) root.dispatchEvent(mouseInit('mousedown', startX, startY, true, event.detail));

      function move(ev) {
        if (drag) return;
        if (Math.abs(ev.clientX - startX) + Math.abs(ev.clientY - startY) < 4) return;
        drag = true;
        root.dispatchEvent(mouseInit('mousedown', startX, startY, true, 1));
      }

      function up() {
        document.removeEventListener('mousemove', move, true);
        document.removeEventListener('mouseup', up, false);
        if (!drag) {
          root.dispatchEvent(mouseInit('mousedown', startX, startY, false, 1));
          root.dispatchEvent(mouseInit('mouseup', startX, startY, false, 1));
          return;
        }
        const text = term.getSelection();
        if (text) {
          copyText(text);
          if (term.clearSelection) term.clearSelection();
          showCopied(term);
          term.focus();
        }
      }

      document.addEventListener('mousemove', move, true);
      document.addEventListener('mouseup', up, false);
    }, true);
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
    if (term.parser && term.parser.registerOscHandler) {
      term.parser.registerOscHandler(52, function (data) {
        const parts = String(data).split(';');
        if (parts.length < 2 || parts[1] === '?') return false;
        try {
          const bytes = Uint8Array.from(atob(parts[1]), function (ch) { return ch.charCodeAt(0); });
          const text = new TextDecoder().decode(bytes);
          if (text) copyText(text);
        } catch (err) {}
        return true;
      });
    }
    attachMouseCopy(term);
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
