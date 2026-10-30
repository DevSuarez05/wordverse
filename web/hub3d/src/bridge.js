// Puente postMessage entre la escena Three.js (iframe) y Flutter (ventana padre).
// Protocolo: strings JSON con { source: 'hub3d' | 'wordverse', type, ... }.
export function createBridge() {
  const inFrame = window.parent !== window;
  const listeners = [];
  window.addEventListener('message', (e) => {
    let d = e.data;
    if (typeof d === 'string') {
      try { d = JSON.parse(d); } catch { return; }
    }
    if (!d || d.source !== 'wordverse') return;
    for (const l of listeners) l(d);
  });
  return {
    inFrame,
    send(msg) {
      if (!inFrame) return;
      window.parent.postMessage(JSON.stringify({ source: 'hub3d', ...msg }), '*');
    },
    onMessage(fn) { listeners.push(fn); },
  };
}
