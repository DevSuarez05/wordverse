import * as THREE from 'three';

/** Crea una CanvasTexture a partir de una función de dibujo 2D. */
export function canvasTexture(w, h, draw, { srgb = true, repeat = false } = {}) {
  const canvas = document.createElement('canvas');
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext('2d');
  draw(ctx, w, h);
  const tex = new THREE.CanvasTexture(canvas);
  if (srgb) tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = 8;
  if (repeat) {
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
  }
  return tex;
}

export function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

export function drawLogo(ctx, cx, cy, r, color = '#22d3ee') {
  ctx.save();
  ctx.shadowColor = color;
  ctx.shadowBlur = r * 0.35;
  ctx.lineWidth = r * 0.1;
  ctx.strokeStyle = color;
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.stroke();
  ctx.restore();
  ctx.fillStyle = 'rgba(4,16,36,0.85)';
  ctx.beginPath();
  ctx.arc(cx, cy, r * 0.9, 0, Math.PI * 2);
  ctx.fill();
  // Visor VR estilizado sobre la "W"
  ctx.lineWidth = r * 0.07;
  ctx.strokeStyle = color;
  roundRect(ctx, cx - r * 0.5, cy - r * 0.62, r, r * 0.38, r * 0.12);
  ctx.stroke();
  ctx.fillStyle = color;
  ctx.font = `900 ${r * 1.0}px "Segoe UI", Arial, sans-serif`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('W', cx, cy + r * 0.2);
}

/** Textura de máscara suave circular para partículas volumétricas resplandecientes. */
export function particleGlowTexture({ size = 64, color = 'rgba(255, 217, 120, 0.9)' } = {}) {
  return canvasTexture(size, size, (ctx) => {
    ctx.clearRect(0, 0, size, size);
    const center = size / 2;
    const grad = ctx.createRadialGradient(center, center, 0, center, center, center * 0.9);
    grad.addColorStop(0, '#ffffff');
    grad.addColorStop(0.25, color);
    grad.addColorStop(0.65, 'rgba(212, 175, 55, 0.35)');
    grad.addColorStop(1, 'rgba(0, 0, 0, 0)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, size, size);
  });
}

/** Letrero luminoso: placa oscura con borde neón y texto. */
export function signTexture(text, { w = 1024, h = 192, color = '#22d3ee', font = 82 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = 'rgba(2,11,28,0.94)';
    roundRect(ctx, 8, 8, w - 16, h - 16, 26);
    ctx.fill();
    ctx.shadowColor = color;
    ctx.shadowBlur = 18;
    ctx.lineWidth = 6;
    ctx.strokeStyle = color;
    ctx.stroke();
    ctx.shadowBlur = 0;
    ctx.fillStyle = '#ffffff';
    ctx.font = `800 ${font}px "Segoe UI", Arial, sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(text, w / 2, h / 2 + 4, w - 70);
  });
}

/** Mapa mundial punteado (continentes aproximados) para pantallas y hologramas. */
export function worldMapTexture({ w = 1024, h = 512, dots = 900, seed = 5, color = '#22d3ee' } = {}) {
  let s = seed;
  const rnd = () => ((s = (s * 16807) % 2147483647) / 2147483647);
  // Elipses aproximadas en coordenadas normalizadas (cx, cy, rx, ry)
  const land = [
    [0.2, 0.32, 0.12, 0.17], // Norteamérica
    [0.3, 0.7, 0.06, 0.17], // Sudamérica
    [0.5, 0.28, 0.07, 0.09], // Europa
    [0.52, 0.55, 0.08, 0.17], // África
    [0.7, 0.34, 0.17, 0.16], // Asia
    [0.84, 0.72, 0.06, 0.07], // Oceanía
  ];
  return canvasTexture(w, h, (ctx) => {
    ctx.fillStyle = '#031326';
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = 'rgba(34,211,238,0.10)';
    ctx.lineWidth = 1;
    for (let i = 1; i < 16; i++) {
      ctx.beginPath(); ctx.moveTo((i / 16) * w, 0); ctx.lineTo((i / 16) * w, h); ctx.stroke();
    }
    for (let i = 1; i < 8; i++) {
      ctx.beginPath(); ctx.moveTo(0, (i / 8) * h); ctx.lineTo(w, (i / 8) * h); ctx.stroke();
    }
    for (let i = 0; i < dots; i++) {
      const [cx, cy, rx, ry] = land[Math.floor(rnd() * land.length)];
      const a = rnd() * Math.PI * 2;
      const r = Math.sqrt(rnd());
      const x = (cx + Math.cos(a) * rx * r) * w;
      const y = (cy + Math.sin(a) * ry * r) * h;
      ctx.fillStyle = rnd() > 0.93 ? '#ffffff' : color;
      ctx.globalAlpha = 0.35 + rnd() * 0.65;
      ctx.beginPath();
      ctx.arc(x, y, 1.6 + rnd() * 2.2, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  });
}

/** Tarjeta flotante de hotspot. */
export function hotspotLabelTexture({ code, title, subtitle, color }) {
  const w = 512;
  const h = 200;
  return canvasTexture(w, h, (ctx) => {
    ctx.clearRect(0, 0, w, h);
    const g = ctx.createLinearGradient(0, 0, w, h);
    g.addColorStop(0, 'rgba(10,28,58,0.94)');
    g.addColorStop(1, 'rgba(4,10,24,0.94)');
    ctx.fillStyle = g;
    roundRect(ctx, 8, 8, w - 16, h - 16, 26);
    ctx.fill();
    ctx.shadowColor = color;
    ctx.shadowBlur = 16;
    ctx.lineWidth = 5;
    ctx.strokeStyle = color;
    ctx.stroke();
    ctx.shadowBlur = 0;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillStyle = color;
    ctx.font = '800 30px "Segoe UI", Arial, sans-serif';
    ctx.fillText(code, w / 2, 48);
    ctx.fillStyle = '#ffffff';
    ctx.font = '900 54px "Segoe UI", Arial, sans-serif';
    ctx.fillText(title, w / 2, 103, w - 50);
    ctx.fillStyle = 'rgba(103,232,249,0.9)';
    ctx.font = '600 28px "Segoe UI", Arial, sans-serif';
    ctx.fillText(subtitle, w / 2, 154, w - 50);
  });
}

/** Etiqueta de nombre sobre la cabeza de un avatar. */
export function nameplateTexture({ name, company, status, color }) {
  const w = 512;
  const h = 170;
  const statusColor = { Disponible: '#4ade80', Ocupado: '#fbbf24', 'No disponible': '#f87171' }[status] || '#4ade80';
  return canvasTexture(w, h, (ctx) => {
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = 'rgba(6,16,36,0.92)';
    roundRect(ctx, 8, 8, w - 16, h - 16, 22);
    ctx.fill();
    ctx.shadowColor = color;
    ctx.shadowBlur = 14;
    ctx.lineWidth = 5;
    ctx.strokeStyle = color;
    ctx.stroke();
    ctx.shadowBlur = 0;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillStyle = '#ffffff';
    ctx.font = '800 46px "Segoe UI", Arial, sans-serif';
    ctx.fillText(name, w / 2, 56, w - 50);
    ctx.fillStyle = '#67e8f9';
    ctx.font = '600 29px "Segoe UI", Arial, sans-serif';
    ctx.fillText(company || '', w / 2, 100, w - 50);
    ctx.fillStyle = statusColor;
    ctx.font = '700 28px "Segoe UI", Arial, sans-serif';
    ctx.fillText('● ' + (status || 'Disponible'), w / 2, 138);
  });
}

export function emoteTexture(text) {
  const w = 384;
  const h = 110;
  return canvasTexture(w, h, (ctx) => {
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = '#d97706';
    roundRect(ctx, 6, 6, w - 12, h - 12, 40);
    ctx.fill();
    ctx.fillStyle = '#111827';
    ctx.font = '800 48px "Segoe UI", "Segoe UI Emoji", Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(text, w / 2, h / 2 + 3, w - 40);
  });
}

/** Tarjeta ticker financiera holográfica para el holograma central (Estilo GTA VI / Cyberpunk). */
export function tickerCardTexture({ symbol, title, value, change, color = '#22d3ee' }) {
  const w = 440;
  const h = 150;
  return canvasTexture(w, h, (ctx) => {
    ctx.clearRect(0, 0, w, h);

    // Fondo cápsula oscura glassmorphism con degradado
    const g = ctx.createLinearGradient(0, 0, w, h);
    g.addColorStop(0, 'rgba(8, 22, 48, 0.95)');
    g.addColorStop(1, 'rgba(3, 10, 26, 0.95)');
    ctx.fillStyle = g;
    roundRect(ctx, 8, 8, w - 16, h - 16, 24);
    ctx.fill();

    // Borde brillante con resplandor neón
    ctx.shadowColor = color;
    ctx.shadowBlur = 14;
    ctx.lineWidth = 4;
    ctx.strokeStyle = color;
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Ícono / Símbolo circular a la izquierda
    ctx.fillStyle = 'rgba(255, 255, 255, 0.08)';
    ctx.beginPath();
    ctx.arc(68, 75, 42, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = color;
    ctx.lineWidth = 2.5;
    ctx.stroke();

    ctx.fillStyle = '#ffffff';
    ctx.font = '900 38px "Segoe UI", "Segoe UI Emoji", Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(symbol, 68, 77);

    // Título / Etiqueta superior
    ctx.textAlign = 'left';
    ctx.fillStyle = 'rgba(148, 163, 184, 0.95)';
    ctx.font = '700 24px "Segoe UI", Arial, sans-serif';
    ctx.fillText(title, 130, 48);

    // Valor principal en blanco brillante
    ctx.fillStyle = '#ffffff';
    ctx.font = '900 36px "Segoe UI", Arial, sans-serif';
    ctx.fillText(value, 130, 88);

    // Pill de cambio / estado
    const isUp = !change.startsWith('-');
    ctx.fillStyle = isUp ? 'rgba(34, 197, 94, 0.22)' : 'rgba(239, 68, 68, 0.22)';
    roundRect(ctx, 130, 110, 150, 28, 8);
    ctx.fill();
    ctx.fillStyle = isUp ? '#4ade80' : '#f87171';
    ctx.font = '800 20px "Segoe UI", Arial, sans-serif';
    ctx.fillText(change, 142, 128);
  });
}

/** Lista holográfica "Registro de Empresas Mundiales" (desplazable verticalmente). */
export function registryTexture() {
  const names = [
    'Shest Labs · Global', 'Andes FinTech Latam', 'Nova Pay Europe', 'Orion Logistics Asia',
    'Atlas Capital NY', 'Helix BioTech Zurich', 'Zenith Coffee Bogota', 'Quantum Ledger Tokyo',
  ];
  return canvasTexture(
    1024,
    1024,
    (ctx, w, h) => {
      ctx.clearRect(0, 0, w, h);
      // Título holográfico centrado
      ctx.fillStyle = '#22d3ee';
      ctx.font = '900 42px "Segoe UI", Arial, sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText('🌐 REGISTRO DE EMPRESAS MUNDIALES', w / 2, 70);

      // Líneas de mapa y cuadrícula
      ctx.strokeStyle = 'rgba(34, 211, 238, 0.35)';
      ctx.lineWidth = 2;
      for (let y = 140; y < h; y += 110) {
        ctx.beginPath();
        ctx.moveTo(40, y);
        ctx.lineTo(w - 40, y);
        ctx.stroke();
      }

      // Nombres de empresas con badges modernos
      ctx.textAlign = 'left';
      ctx.textBaseline = 'middle';
      names.forEach((n, i) => {
        const y = 200 + (i * 96);
        if (y > h - 40) return;
        // Fondo translúcido
        ctx.fillStyle = 'rgba(14, 165, 233, 0.16)';
        ctx.fillRect(40, y - 32, w - 80, 64);
        ctx.fillStyle = '#ffffff';
        ctx.font = 'bold 32px "Segoe UI", Arial, sans-serif';
        ctx.fillText('◆ ' + n, 60, y);

        // Badge verified
        ctx.fillStyle = '#38bdf8';
        ctx.font = '600 24px "Segoe UI", Arial, sans-serif';
        ctx.textAlign = 'right';
        ctx.fillText('VERIFICADA ●', w - 60, y);
        ctx.textAlign = 'left';
      });
    },
    { repeat: true },
  );
}

/**
 * Textura PBR Fotorrealista de Mármol Real Calacatta & Nero Marquina (2K).
 * Incluye juntas arquitectónicas de dilatación en latón dorado cepillado y vetas orgánicas fractales.
 */
export function royalMarblePbrTexture({ w = 2048, h = 2048, tileCount = 8 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    // 1. Base mineral Negro Obsidiana (#0A0A0C) profundo y lujoso
    const bgGrad = ctx.createRadialGradient(w / 2, h / 2, w * 0.1, w / 2, h / 2, w * 0.75);
    bgGrad.addColorStop(0, '#10121a');
    bgGrad.addColorStop(0.5, '#0a0a0c');
    bgGrad.addColorStop(1, '#050608');
    ctx.fillStyle = bgGrad;
    ctx.fillRect(0, 0, w, h);

    // 2. Micro-cristales minerales dispersos de Oro y Cian
    for (let i = 0; i < 3500; i++) {
      const mx = Math.random() * w;
      const my = Math.random() * h;
      const alpha = 0.05 + Math.random() * 0.12;
      ctx.fillStyle = Math.random() > 0.3 ? `rgba(212, 175, 55, ${alpha})` : `rgba(0, 240, 255, ${alpha * 0.6})`;
      ctx.fillRect(mx, my, 1 + Math.random() * 2, 1 + Math.random() * 2);
    }

    // 3. Vetas orgánicas primarias en Oro Premium (#D4AF37) y Carbón profundo
    const drawVeinBranch = (startX, startY, endX, endY, depth = 0, maxDepth = 4, width = 6, color = 'rgba(212, 175, 55, 0.35)') => {
      if (depth >= maxDepth) return;
      ctx.strokeStyle = color;
      ctx.lineWidth = Math.max(0.6, width * (1 - depth * 0.22));
      ctx.beginPath();
      ctx.moveTo(startX, startY);

      const midX = (startX + endX) / 2 + (Math.random() - 0.5) * (w * 0.12 / (depth + 1));
      const midY = (startY + endY) / 2 + (Math.random() - 0.5) * (h * 0.12 / (depth + 1));
      ctx.quadraticCurveTo(midX, midY, endX, endY);
      ctx.stroke();

      // Bifurcación lateral fina
      if (Math.random() > 0.35 && depth < 3) {
        const branchX = midX + (Math.random() - 0.5) * (w * 0.18);
        const branchY = midY + (Math.random() - 0.5) * (h * 0.18);
        drawVeinBranch(midX, midY, branchX, branchY, depth + 1, maxDepth, width * 0.55, 'rgba(212, 175, 55, 0.22)');
      }
    };

    // Vetas monumentales principales en Oro Premium
    for (let i = 0; i < 16; i++) {
      const p1x = Math.random() * w;
      const p1y = (i % 2 === 0) ? 0 : Math.random() * h;
      const p2x = (i % 2 === 0) ? Math.random() * w : w;
      const p2y = (i % 2 === 0) ? h : Math.random() * h;
      drawVeinBranch(p1x, p1y, p2x, p2y, 0, 4, 7.5, 'rgba(212, 175, 55, 0.32)');
    }

    // Vetas sutiles secundarias en Cian Holográfico suave
    for (let i = 0; i < 10; i++) {
      const gx1 = Math.random() * w;
      const gy1 = Math.random() * h;
      const gx2 = gx1 + (Math.random() - 0.5) * (w * 0.4);
      const gy2 = gy1 + (Math.random() - 0.5) * (h * 0.4);
      drawVeinBranch(gx1, gy1, gx2, gy2, 0, 3, 3.0, 'rgba(0, 240, 255, 0.18)');
    }

    // 4. Juntas de dilatación en latón pulido (Brass Inlay Grid) en Oro Premium
    const tileSize = w / tileCount;
    ctx.lineWidth = 3.5;
    ctx.strokeStyle = 'rgba(212, 175, 55, 0.65)';
    for (let x = 0; x <= w; x += tileSize) {
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke();
    }
    for (let y = 0; y <= h; y += tileSize) {
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
    }

    // Filete interior de brillo dorado
    ctx.lineWidth = 1;
    ctx.strokeStyle = 'rgba(255, 235, 160, 0.5)';
    for (let x = 0; x <= w; x += tileSize) {
      ctx.beginPath(); ctx.moveTo(x + 1, 0); ctx.lineTo(x + 1, h); ctx.stroke();
    }
    for (let y = 0; y <= h; y += tileSize) {
      ctx.beginPath(); ctx.moveTo(0, y + 1); ctx.lineTo(w, y + 1); ctx.stroke();
    }
  });
}

/**
 * Palillería Acústica Arquitectónica de Madera de Nogal con retroiluminación y relieve.
 */
export function flutedWoodTexture({ w = 1024, h = 1024, slats = 36 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    // Fondo de ranura profunda
    ctx.fillStyle = '#0f0e0c';
    ctx.fillRect(0, 0, w, h);

    const slatWidth = w / slats;
    const gap = slatWidth * 0.22;
    const woodWidth = slatWidth - gap;

    for (let i = 0; i < slats; i++) {
      const x = i * slatWidth + gap / 2;

      // Degradado natural de la madera de nogal
      const woodGrad = ctx.createLinearGradient(x, 0, x + woodWidth, 0);
      woodGrad.addColorStop(0, '#261e17');
      woodGrad.addColorStop(0.18, '#3d2e21');
      woodGrad.addColorStop(0.5, '#4a382a');
      woodGrad.addColorStop(0.82, '#3d2e21');
      woodGrad.addColorStop(1, '#211913');
      ctx.fillStyle = woodGrad;
      ctx.fillRect(x, 0, woodWidth, h);

      // Vetas verticales sutiles de la madera
      ctx.strokeStyle = 'rgba(28, 20, 14, 0.45)';
      ctx.lineWidth = 1.2;
      for (let j = 0; j < 3; j++) {
        const vx = x + 3 + Math.random() * (woodWidth - 6);
        ctx.beginPath();
        ctx.moveTo(vx, 0);
        ctx.bezierCurveTo(vx + (Math.random() - 0.5) * 4, h * 0.4, vx + (Math.random() - 0.5) * 4, h * 0.7, vx, h);
        ctx.stroke();
      }

      // Bisel de luz superior / lateral
      ctx.strokeStyle = 'rgba(255, 237, 213, 0.18)';
      ctx.lineWidth = 1;
      ctx.beginPath(); ctx.moveTo(x + 1, 0); ctx.lineTo(x + 1, h); ctx.stroke();

      // Sombra de oclusión en la ranura
      ctx.strokeStyle = 'rgba(0, 0, 0, 0.65)';
      ctx.lineWidth = 1.5;
      ctx.beginPath(); ctx.moveTo(x + woodWidth, 0); ctx.lineTo(x + woodWidth, h); ctx.stroke();
    }
  }, { repeat: true });
}

/**
 * Piedra Ónix Traslúcida Retroiluminada para el pedestal central y frontal de recepción.
 */
export function backlitOnyxTexture({ w = 1024, h = 512, color = '#22d3ee' } = {}) {
  return canvasTexture(w, h, (ctx) => {
    // Fondo de difusión interna
    const grad = ctx.createLinearGradient(0, 0, w, h);
    grad.addColorStop(0, '#03172e');
    grad.addColorStop(0.5, '#06284a');
    grad.addColorStop(1, '#021324');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, w, h);

    // Nubes minerales translúcidas
    for (let i = 0; i < 40; i++) {
      const cx = Math.random() * w;
      const cy = Math.random() * h;
      const cr = 40 + Math.random() * 90;
      const cGrad = ctx.createRadialGradient(cx, cy, cr * 0.1, cx, cy, cr);
      cGrad.addColorStop(0, 'rgba(56, 189, 248, 0.35)');
      cGrad.addColorStop(0.6, 'rgba(14, 165, 233, 0.15)');
      cGrad.addColorStop(1, 'rgba(2, 132, 199, 0)');
      ctx.fillStyle = cGrad;
      ctx.beginPath();
      ctx.arc(cx, cy, cr, 0, Math.PI * 2);
      ctx.fill();
    }

    // Fisuras cristalinas brillantes
    ctx.strokeStyle = 'rgba(186, 230, 253, 0.45)';
    ctx.lineWidth = 1.8;
    for (let i = 0; i < 8; i++) {
      ctx.beginPath();
      ctx.moveTo(Math.random() * w, 0);
      ctx.bezierCurveTo(Math.random() * w, h * 0.3, Math.random() * w, h * 0.7, Math.random() * w, h);
      ctx.stroke();
    }
  });
}

/**
 * Cuero Nappa Ejecutivo Acolchado con Pespuntes en Diamante (Capitoné).
 */
export function quiltedLeatherTexture({ w = 1024, h = 1024, count = 8 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    ctx.fillStyle = '#0f172a';
    ctx.fillRect(0, 0, w, h);

    const step = w / count;

    // Relleno acolchado con efecto de abombado 3D (radial) en cada rombo
    for (let i = 0; i < count; i++) {
      for (let j = 0; j < count; j++) {
        const cx = (i + 0.5) * step;
        const cy = (j + 0.5) * step;
        const grad = ctx.createRadialGradient(cx, cy, 4, cx, cy, step * 0.65);
        grad.addColorStop(0, '#1e293b');
        grad.addColorStop(0.55, '#141e30');
        grad.addColorStop(1, '#090d16');
        ctx.fillStyle = grad;
        ctx.fillRect(i * step, j * step, step, step);
      }
    }

    // Costuras diagonales entrecruzadas
    ctx.strokeStyle = 'rgba(2, 6, 23, 0.85)';
    ctx.lineWidth = 3.5;
    for (let k = -count; k <= count * 2; k++) {
      // Diagonal descendente
      ctx.beginPath();
      ctx.moveTo(k * step, 0);
      ctx.lineTo((k + count) * step, h);
      ctx.stroke();

      // Diagonal ascendente
      ctx.beginPath();
      ctx.moveTo(k * step, h);
      ctx.lineTo((k + count) * step, 0);
      ctx.stroke();
    }

    // Hilo de pespunte claro con puntadas discontinuas
    ctx.setLineDash([4, 4]);
    ctx.strokeStyle = 'rgba(148, 163, 184, 0.45)';
    ctx.lineWidth = 1.4;
    for (let k = -count; k <= count * 2; k++) {
      ctx.beginPath();
      ctx.moveTo(k * step, 0);
      ctx.lineTo((k + count) * step, h);
      ctx.stroke();

      ctx.beginPath();
      ctx.moveTo(k * step, h);
      ctx.lineTo((k + count) * step, 0);
      ctx.stroke();
    }
    ctx.setLineDash([]); // Restaurar continuo

    // Botones / Nódulos hundidos en las intersecciones
    for (let i = 0; i <= count; i++) {
      for (let j = 0; j <= count; j++) {
        const bx = i * step;
        const by = j * step;
        ctx.fillStyle = '#020617';
        ctx.beginPath();
        ctx.arc(bx, by, 5, 0, Math.PI * 2);
        ctx.fill();

        ctx.fillStyle = '#475569';
        ctx.beginPath();
        ctx.arc(bx - 1, by - 1, 2, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }, { repeat: true });
}

/**
 * Skyline Metropolitano Panorámico Fotorrealista para el Muro Cortina de Doble Altura.
 */
export function panoramicSkylineTexture({ w = 2048, h = 512 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    // 1. Cielo crepuscular nocturno con degradado atmosférico
    const skyGrad = ctx.createLinearGradient(0, 0, 0, h);
    skyGrad.addColorStop(0, '#020617');
    skyGrad.addColorStop(0.55, '#071329');
    skyGrad.addColorStop(0.85, '#0c2242');
    skyGrad.addColorStop(1, '#0e3a5d');
    ctx.fillStyle = skyGrad;
    ctx.fillRect(0, 0, w, h);

    // 2. Estrellas y bruma urbana lejana
    for (let i = 0; i < 350; i++) {
      const sx = Math.random() * w;
      const sy = Math.random() * (h * 0.55);
      const alpha = 0.2 + Math.random() * 0.7;
      ctx.fillStyle = `rgba(255, 255, 255, ${alpha})`;
      ctx.fillRect(sx, sy, 1.2, 1.2);
    }

    // 3. Rascacielos en capas de profundidad (Capa lejana más oscura, capa cercana nítida)
    const towerLayers = [
      { count: 28, yBase: h * 0.28, color: '#09152b', alpha: 0.65, minW: 35, maxW: 65 },
      { count: 20, yBase: h * 0.20, color: '#050e1e', alpha: 0.85, minW: 55, maxW: 95 },
      { count: 15, yBase: h * 0.12, color: '#020712', alpha: 1.0, minW: 80, maxW: 130 },
    ];

    towerLayers.forEach((layer) => {
      ctx.fillStyle = layer.color;
      ctx.globalAlpha = layer.alpha;

      for (let i = 0; i < layer.count; i++) {
        const tx = (i / layer.count) * w + (Math.random() - 0.5) * 40;
        const tw = layer.minW + Math.random() * (layer.maxW - layer.minW);
        const th = h - layer.yBase - Math.random() * (h * 0.55);

        ctx.fillRect(tx, h - th, tw, th);

        // Antena / aguja de telecomunicaciones en el techo
        if (Math.random() > 0.4) {
          ctx.fillRect(tx + tw / 2 - 1.5, h - th - 35, 3, 35);
          // Baliza roja aeronáutica en la cima
          ctx.fillStyle = '#ef4444';
          ctx.beginPath();
          ctx.arc(tx + tw / 2, h - th - 36, 2.5, 0, Math.PI * 2);
          ctx.fill();
          ctx.fillStyle = layer.color;
        }

        // Matriz de ventanas encendidas (blanco cálido, cian y dorado)
        const winCols = Math.floor(tw / 8);
        const winRows = Math.floor(th / 10);
        for (let r = 2; r < winRows - 1; r++) {
          for (let c = 1; c < winCols - 1; c++) {
            if (Math.random() > 0.52) {
              const wx = tx + c * 8;
              const wy = h - th + r * 10;
              const randColor = Math.random();
              ctx.fillStyle = randColor > 0.6 ? '#fef08a' : (randColor > 0.25 ? '#38bdf8' : '#e2e8f0');
              ctx.globalAlpha = 0.4 + Math.random() * 0.5;
              ctx.fillRect(wx, wy, 4.5, 4.5);
            }
          }
        }
        ctx.fillStyle = layer.color;
        ctx.globalAlpha = layer.alpha;
      }
    });

    ctx.globalAlpha = 1.0;

    // 4. Autopista elevada inferior con flujo de luces vehiculares
    const roadY = h - 16;
    ctx.fillStyle = 'rgba(239, 68, 68, 0.75)'; // Luces traseras rojas
    for (let x = 0; x < w; x += 18) {
      ctx.fillRect(x, roadY, 12, 2.5);
    }
    ctx.fillStyle = 'rgba(254, 240, 138, 0.85)'; // Faros delanteros dorados
    for (let x = 0; x < w; x += 16) {
      ctx.fillRect(x + 8, roadY + 5, 10, 2.5);
    }
  });
}

/**
 * Textura de Fibra de Carbono Twill para paredes y mesas de la Sala Privada.
 */
export function carbonFiberTexture({ w = 256, h = 256 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    ctx.fillStyle = '#0a0a0c';
    ctx.fillRect(0, 0, w, h);
    const step = 8;
    for (let x = 0; x < w; x += step) {
      for (let y = 0; y < h; y += step) {
        const isLight = ((x + y) / step) % 2 === 0;
        ctx.fillStyle = isLight ? '#1a1d24' : '#0e1014';
        ctx.fillRect(x, y, step, step);
        ctx.strokeStyle = 'rgba(255,255,255,0.04)';
        ctx.strokeRect(x, y, step, step);
      }
    }
  }, { repeat: true });
}

/**
 * Emblema Mural PREMION 3D BUSINESS HUB & VIP PRIVATE BOARDROOM (Fiel al Concept Art).
 */
export function premionEmblemTexture({ type = 'lobby', w = 1024, h = 1024 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    ctx.clearRect(0, 0, w, h);

    // Fondo hexagonal con bisel dorado y textura interior oscura
    const cx = w / 2;
    const cy = h / 2;
    const r = w * 0.44;

    ctx.save();
    ctx.beginPath();
    for (let i = 0; i < 6; i++) {
      const a = (i * Math.PI) / 3 - Math.PI / 6;
      const x = cx + Math.cos(a) * r;
      const y = cy + Math.sin(a) * r;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.closePath();

    // Degradado interior negro obsidiana
    const g = ctx.createRadialGradient(cx, cy, r * 0.1, cx, cy, r);
    g.addColorStop(0, '#121318');
    g.addColorStop(0.7, '#08080a');
    g.addColorStop(1, '#020203');
    ctx.fillStyle = g;
    ctx.fill();

    // Borde de Oro Premium brillante
    ctx.shadowColor = '#d4af37';
    ctx.shadowBlur = 28;
    ctx.lineWidth = 14;
    ctx.strokeStyle = '#d4af37';
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Segundo aro interior fino
    ctx.lineWidth = 3;
    ctx.strokeStyle = '#fef08a';
    ctx.stroke();
    ctx.restore();

    if (type === 'lobby') {
      // 1. Logotipo circular superior "W" dorado
      const logoY = cy - r * 0.38;
      ctx.save();
      ctx.beginPath();
      ctx.arc(cx, logoY, 75, 0, Math.PI * 2);
      ctx.fillStyle = '#0a0a0c';
      ctx.fill();
      ctx.lineWidth = 8;
      ctx.strokeStyle = '#d4af37';
      ctx.shadowColor = '#d4af37';
      ctx.shadowBlur = 18;
      ctx.stroke();
      ctx.restore();

      ctx.fillStyle = '#d4af37';
      ctx.font = '900 85px "Segoe UI", Arial, sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('W', cx, logoY + 4);

      // 2. Tipografía PREMION en Oro brillante
      ctx.fillStyle = '#ffffff';
      ctx.font = '900 94px "Segoe UI", Arial, sans-serif';
      ctx.shadowColor = '#d4af37';
      ctx.shadowBlur = 14;
      ctx.fillText('PREMION', cx, cy + 50);

      // 3. Subtítulo "3D BUSINESS HUB"
      ctx.shadowBlur = 0;
      ctx.fillStyle = '#d4af37';
      ctx.font = '800 40px "Segoe UI", Arial, sans-serif';
      ctx.fillText('3D BUSINESS HUB', cx, cy + 120);

      // 4. Etiqueta "LOBBY"
      ctx.fillStyle = '#00f0ff';
      ctx.font = '700 36px "Segoe UI", Arial, sans-serif';
      ctx.fillText('LOBBY · SALA PRINCIPAL', cx, cy + 185);
    } else {
      // Tablero "PREMION VIP PRIVATE BOARDROOM"
      ctx.fillStyle = '#d4af37';
      ctx.font = '900 86px "Segoe UI", Arial, sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.shadowColor = '#d4af37';
      ctx.shadowBlur = 20;
      ctx.fillText('PREMION VIP', cx, cy - 40);

      ctx.fillStyle = '#ffffff';
      ctx.font = '900 56px "Segoe UI", Arial, sans-serif';
      ctx.shadowBlur = 10;
      ctx.fillText('PRIVATE BOARDROOM', cx, cy + 45);

      ctx.fillStyle = '#7b2cbf';
      ctx.font = '700 34px "Segoe UI", Arial, sans-serif';
      ctx.fillText('CONFERENCIAS CONFIDENCIALES', cx, cy + 120);
    }
  });
}

/**
 * Letrero de Portal de Acceso (SALA PÚBLICA / SALA PRIVADA) con Neón y Arco Luminoso.
 */
export function premionPortalSignTexture({ title, color = '#00f0ff', w = 512, h = 150 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = 'rgba(10, 10, 12, 0.94)';
    roundRect(ctx, 8, 8, w - 16, h - 16, 20);
    ctx.fill();

    ctx.shadowColor = color;
    ctx.shadowBlur = 16;
    ctx.lineWidth = 6;
    ctx.strokeStyle = color;
    ctx.stroke();
    ctx.shadowBlur = 0;

    ctx.fillStyle = '#ffffff';
    ctx.font = '900 50px "Segoe UI", Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(title, w / 2, h / 2);
  });
}

/**
 * Textura para los 4 Pilares de Cada Logo en una Esquina (Wordverse, Shest, Escrow, P2P).
 */
export function premionCornerPillarTexture({ brand, symbol, title, subtitle, color = '#00f0ff', w = 512, h = 1024 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    // Fondo negro obsidiana con marco metálico
    const g = ctx.createLinearGradient(0, 0, 0, h);
    g.addColorStop(0, '#10121a');
    g.addColorStop(0.5, '#0a0a0c');
    g.addColorStop(1, '#050508');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, w, h);

    // Borde brillante con el color corporativo
    ctx.shadowColor = color;
    ctx.shadowBlur = 18;
    ctx.lineWidth = 8;
    ctx.strokeStyle = color;
    ctx.strokeRect(12, 12, w - 24, h - 24);
    ctx.shadowBlur = 0;

    // Medallón circular superior para el símbolo
    const cx = w / 2;
    const cy = 240;
    ctx.beginPath();
    ctx.arc(cx, cy, 110, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(255, 255, 255, 0.06)';
    ctx.fill();
    ctx.lineWidth = 6;
    ctx.strokeStyle = color;
    ctx.stroke();

    ctx.fillStyle = '#ffffff';
    ctx.font = '900 96px "Segoe UI", "Segoe UI Emoji", Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(symbol, cx, cy + 4);

    // Título de la marca
    ctx.fillStyle = '#ffffff';
    ctx.font = '900 54px "Segoe UI", Arial, sans-serif';
    ctx.fillText(title, cx, 470);

    // Subtítulo
    ctx.fillStyle = color;
    ctx.font = '800 32px "Segoe UI", Arial, sans-serif';
    ctx.fillText(subtitle, cx, 540);

    // Status / Actividad
    ctx.fillStyle = '#d4af37';
    ctx.font = '700 28px "Segoe UI", Arial, sans-serif';
    ctx.fillText('● RED VERIFICADA', cx, 620);

    // Gráficos holográficos en la base
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.2)';
    ctx.lineWidth = 2;
    for (let y = 700; y < 960; y += 40) {
      ctx.beginPath();
      ctx.moveTo(60, y);
      ctx.lineTo(w - 60, y);
      ctx.stroke();
    }
  });
}

/**
 * Holograma Central 3D de la Mesa de Juntas (Sala Privada - The Boardroom).
 * Mapa mundial en Cian y Púrpura Nebulosa con gráficas financieras laterales.
 */
export function boardroomHoloMapTexture({ w = 1024, h = 512 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    ctx.fillStyle = 'rgba(6, 10, 24, 0.75)';
    ctx.fillRect(0, 0, w, h);

    // Cuadrícula táctica en Cian suave
    ctx.strokeStyle = 'rgba(0, 240, 255, 0.15)';
    ctx.lineWidth = 1.2;
    for (let x = 0; x < w; x += 40) {
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke();
    }
    for (let y = 0; y < h; y += 40) {
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
    }

    // Continentes en Cian Holográfico y Púrpura Nebulosa
    const landClusters = [
      { cx: 0.28, cy: 0.38, rx: 110, ry: 75, col: '#00f0ff' }, // Norteamérica
      { cx: 0.35, cy: 0.68, rx: 65, ry: 95, col: '#00f0ff' },  // Sudamérica
      { cx: 0.54, cy: 0.32, rx: 80, ry: 55, col: '#7b2cbf' },  // Europa
      { cx: 0.56, cy: 0.58, rx: 85, ry: 95, col: '#7b2cbf' },  // África
      { cx: 0.72, cy: 0.40, rx: 140, ry: 90, col: '#00f0ff' }, // Asia
      { cx: 0.82, cy: 0.74, rx: 65, ry: 55, col: '#7b2cbf' },  // Oceanía
    ];

    landClusters.forEach((c) => {
      ctx.fillStyle = c.col;
      ctx.globalAlpha = 0.65;
      for (let i = 0; i < 90; i++) {
        const ang = Math.random() * Math.PI * 2;
        const dist = Math.sqrt(Math.random());
        const x = c.cx * w + Math.cos(ang) * c.rx * dist;
        const y = c.cy * h + Math.sin(ang) * c.ry * dist;
        ctx.beginPath();
        ctx.arc(x, y, 2.2 + Math.random() * 2.8, 0, Math.PI * 2);
        ctx.fill();
      }
    });

    ctx.globalAlpha = 1.0;

    // Gráficas financieras a los lados
    // Izquierda: Curva de cotización en Cian
    ctx.strokeStyle = '#00f0ff';
    ctx.lineWidth = 3.5;
    ctx.beginPath();
    ctx.moveTo(30, 420);
    ctx.lineTo(80, 390);
    ctx.lineTo(130, 405);
    ctx.lineTo(180, 340);
    ctx.lineTo(230, 310);
    ctx.stroke();

    // Derecha: Gráfica de barras en Púrpura
    ctx.fillStyle = '#7b2cbf';
    for (let i = 0; i < 6; i++) {
      const bh = 50 + i * 25;
      ctx.fillRect(w - 240 + i * 35, 430 - bh, 24, bh);
    }

    // Título superior central
    ctx.fillStyle = '#00f0ff';
    ctx.font = '800 28px "Segoe UI", Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('GLOBAL EXECUTIVE DATA FLOW · CONFIDENTIAL', w / 2, 42);
  });
}

export const BOARDROOM_SLIDES = [
  { id: 0, title: 'MAPA TÁCTICO GLOBAL', subtitle: 'Flujo Financiero P2P & Nodos Activos' },
  { id: 1, title: 'AUDITORÍA Q4 & ESCROW', subtitle: 'Rendimiento TRC20 · 99.98% SLA' },
  { id: 2, title: 'ARQUITECTURA MULTI-SIG', subtitle: 'Contratos Inteligentes E2EE & Vaults' },
  { id: 3, title: 'SYNDICATE ROUND 2026', subtitle: 'Alocación de Capital & Expansión' },
];

/** Diapositivas ejecutivas interactivas para el holograma 3D de The Boardroom. */
export function boardroomSlideTexture(slideIdx = 0, { w = 1024, h = 512 } = {}) {
  const idx = Math.abs(slideIdx) % BOARDROOM_SLIDES.length;
  if (idx === 0) return boardroomHoloMapTexture({ w, h });

  return canvasTexture(w, h, (ctx) => {
    ctx.fillStyle = 'rgba(6, 10, 24, 0.88)';
    ctx.fillRect(0, 0, w, h);

    // Cuadrícula táctica en Cian/Oro
    ctx.strokeStyle = 'rgba(0, 240, 255, 0.12)';
    ctx.lineWidth = 1;
    for (let x = 0; x < w; x += 40) {
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke();
    }
    for (let y = 0; y < h; y += 40) {
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
    }

    // Cabecera de la diapositiva
    const slide = BOARDROOM_SLIDES[idx];
    ctx.fillStyle = '#0a1628';
    ctx.fillRect(40, 20, w - 80, 75);
    ctx.strokeStyle = '#d4af37';
    ctx.lineWidth = 2;
    ctx.strokeRect(40, 20, w - 80, 75);

    ctx.fillStyle = '#d4af37';
    ctx.font = '900 16px "Segoe UI", sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText(`DIAPOSITIVA ${idx + 1} DE ${BOARDROOM_SLIDES.length} · CONFIDENCIAL E2EE`, 60, 48);

    ctx.fillStyle = '#00f0ff';
    ctx.font = '800 26px "Segoe UI", sans-serif';
    ctx.fillText(`${slide.title} — ${slide.subtitle}`, 60, 78);

    if (idx === 1) {
      // SLIDE 1: AUDITORÍA Q4 & ESCROW
      // 3 Tarjetas KPI en Oro y Cian
      const kpis = [
        { label: 'VOLUMEN ESCROW Q4', val: '$48,500,000 USDT', ch: '+24.6% vs Q3', color: '#00ff87' },
        { label: 'CONTRATOS AUDITADOS', val: '12,480 P2P', ch: '0% Default', color: '#00f0ff' },
        { label: 'TIEMPO MEDIO LIQUIDACIÓN', val: '38.2 Segundos', ch: 'TRC20 Instantáneo', color: '#ffd978' },
      ];
      kpis.forEach((k, i) => {
        const x = 50 + i * 315;
        ctx.fillStyle = 'rgba(15, 25, 45, 0.75)';
        ctx.fillRect(x, 120, 295, 130);
        ctx.strokeStyle = k.color;
        ctx.lineWidth = 1.5;
        ctx.strokeRect(x, 120, 295, 130);

        ctx.fillStyle = '#a1a6b0';
        ctx.font = '700 13px "Segoe UI", sans-serif';
        ctx.fillText(k.label, x + 16, 148);

        ctx.fillStyle = '#ffffff';
        ctx.font = '900 24px "Segoe UI", sans-serif';
        ctx.fillText(k.val, x + 16, 190);

        ctx.fillStyle = k.color;
        ctx.font = 'bold 14px "Segoe UI", sans-serif';
        ctx.fillText(k.ch, x + 16, 226);
      });

      // Gráfica de barras de crecimiento trimestral
      ctx.fillStyle = '#a1a6b0';
      ctx.font = '700 14px "Segoe UI", sans-serif';
      ctx.fillText('EVOLUCIÓN MENSUAL DE LIQUIDEZ (MILLONES USD)', 50, 285);

      const months = ['Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      const vals = [28, 33, 37, 41, 44, 48.5];
      months.forEach((m, i) => {
        const bx = 120 + i * 140;
        const bh = vals[i] * 3.6;
        const bGrad = ctx.createLinearGradient(bx, 460 - bh, bx, 460);
        bGrad.addColorStop(0, '#00f0ff');
        bGrad.addColorStop(1, '#7b2cbf');
        ctx.fillStyle = bGrad;
        ctx.fillRect(bx, 460 - bh, 65, bh);

        ctx.fillStyle = '#ffffff';
        ctx.font = 'bold 13px "Segoe UI", sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(`$${vals[i]}M`, bx + 32, 450 - bh);
        ctx.fillText(m, bx + 32, 480);
      });

    } else if (idx === 2) {
      // SLIDE 2: ARQUITECTURA SMART CONTRACTS & MULTI-SIG
      const pillars = [
        { t: '1. Multi-Sig Vaults 3/5', d: 'Custodia institucional con hardware keys distribuidas y timelocks.' },
        { t: '2. Zero-Knowledge Proofs', d: 'Validación de solvencia sin exponer balances privados ni historial.' },
        { t: '3. Arbitraje Descentralizado', d: 'Mesa de mediación certificada con resolución de disputas en <15 min.' },
      ];
      pillars.forEach((p, i) => {
        const y = 125 + i * 115;
        ctx.fillStyle = 'rgba(20, 25, 45, 0.85)';
        ctx.fillRect(60, y, w - 120, 95);
        ctx.strokeStyle = '#7b2cbf';
        ctx.lineWidth = 1.8;
        ctx.strokeRect(60, y, w - 120, 95);

        ctx.fillStyle = '#ffd978';
        ctx.font = '900 18px "Segoe UI", sans-serif';
        ctx.textAlign = 'left';
        ctx.fillText(p.t, 85, y + 36);

        ctx.fillStyle = '#e2e8f0';
        ctx.font = '500 15px "Segoe UI", sans-serif';
        ctx.fillText(p.d, 85, y + 68);
      });

    } else if (idx === 3) {
      // SLIDE 3: SYNDICATE ROUND & EXPANSION
      ctx.fillStyle = '#ffffff';
      ctx.font = '700 15px "Segoe UI", sans-serif';
      ctx.textAlign = 'left';
      ctx.fillText('RONDA SERIE A: ALLOCATION DE CAPITAL', 60, 135);

      const allocations = [
        { name: 'Desarrollo Core & WebGL Engine', pct: '40%', col: '#00f0ff' },
        { name: 'Reserva de Liquidez Escrow USDT', pct: '30%', col: '#ffd978' },
        { name: 'Licencias Regulatorias & Compliance', pct: '20%', col: '#00ff87' },
        { name: 'Expansión Global LatAm & EMEA', pct: '10%', col: '#7b2cbf' },
      ];
      allocations.forEach((a, i) => {
        const y = 160 + i * 75;
        ctx.fillStyle = a.col;
        ctx.fillRect(60, y, 16, 45);

        ctx.fillStyle = '#ffffff';
        ctx.font = 'bold 17px "Segoe UI", sans-serif';
        ctx.fillText(a.name, 90, y + 28);

        ctx.fillStyle = a.col;
        ctx.font = '900 22px "Segoe UI", sans-serif';
        ctx.fillText(a.pct, w - 160, y + 28);
      });
    }
  });
}

/**
 * Gran Panel Mural PREMION 3D BUSINESS ROOM (Dorado y Negro Obsidiana).
 * Fiel a la imagen media_1793083093848_9969c340.jpg.
 */
export function premionWallGoldPanelTexture({ w = 1024, h = 1024 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    // Fondo negro obsidiana con degradado sutil
    const grad = ctx.createLinearGradient(0, 0, w, h);
    grad.addColorStop(0, '#0d0f17');
    grad.addColorStop(0.5, '#07090e');
    grad.addColorStop(1, '#05060a');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, w, h);

    // Marco exterior en Oro Premium con doble filete
    ctx.strokeStyle = '#d4af37';
    ctx.lineWidth = 14;
    ctx.strokeRect(24, 24, w - 48, h - 48);

    ctx.strokeStyle = 'rgba(212, 175, 55, 0.45)';
    ctx.lineWidth = 4;
    ctx.strokeRect(48, 48, w - 96, h - 96);

    // Escuadras en las cuatro esquinas
    const bLen = 60;
    ctx.fillStyle = '#d4af37';
    for (const [bx, by] of [[52, 52], [w - 52 - bLen, 52], [52, h - 52 - bLen], [w - 52 - bLen, h - 52 - bLen]]) {
      ctx.fillRect(bx, by, bLen, 10);
    }

    // Escudo Circular Central en Oro
    const cx = w / 2;
    const cy = 340;
    const cr = 140;

    // Resplandor dorado
    ctx.shadowColor = '#d4af37';
    ctx.shadowBlur = 28;
    ctx.strokeStyle = '#d4af37';
    ctx.lineWidth = 12;
    ctx.beginPath();
    ctx.arc(cx, cy, cr, 0, Math.PI * 2);
    ctx.stroke();

    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.arc(cx, cy, cr - 20, 0, Math.PI * 2);
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Logotipo [W] estilizado en oro
    ctx.fillStyle = '#d4af37';
    ctx.font = '900 130px "Segoe UI", Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('W', cx, cy + 12);

    // Tipografía monumental PREMION
    ctx.shadowColor = '#d4af37';
    ctx.shadowBlur = 18;
    ctx.fillStyle = '#f8f4e6';
    ctx.font = '900 92px "Segoe UI", Arial, sans-serif';
    ctx.fillText('PREMION', cx, 600);
    ctx.shadowBlur = 0;

    // Subtítulo: 3D BUSINESS ROOM
    ctx.fillStyle = '#d4af37';
    ctx.font = '700 38px "Segoe UI", Arial, sans-serif';
    ctx.letterSpacing = '6px';
    ctx.fillText('3D BUSINESS ROOM', cx, 680);

    // Línea divisoria decorativa con rombo central
    ctx.strokeStyle = '#d4af37';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(cx - 240, 750);
    ctx.lineTo(cx - 30, 750);
    ctx.moveTo(cx + 30, 750);
    ctx.lineTo(cx + 240, 750);
    ctx.stroke();

    ctx.fillStyle = '#d4af37';
    ctx.beginPath();
    ctx.moveTo(cx, 742);
    ctx.lineTo(cx + 12, 750);
    ctx.lineTo(cx, 758);
    ctx.lineTo(cx - 12, 750);
    ctx.closePath();
    ctx.fill();

    // Pie de placa
    ctx.fillStyle = 'rgba(212, 175, 55, 0.7)';
    ctx.font = '600 24px "Segoe UI", Arial, sans-serif';
    ctx.letterSpacing = '3px';
    ctx.fillText('EXECUTIVE HEADQUARTERS · LEVEL 1', cx, 830);
  });
}

/**
 * Placa Neón Flotante de Valeria Mendez (Exacta a la imagen).
 * [Valeria Mendez] [● STATUS: AVAILABLE] [• Director]
 */
export function valeriaMendezBadgeTexture({ w = 512, h = 220 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    // Fondo oscuro translúcido con esquinas muy redondeadas
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = 'rgba(10, 10, 22, 0.92)';
    roundRect(ctx, 10, 10, w - 20, h - 20, 28);
    ctx.fill();

    // Borde neón púrpura/magenta vibrante
    ctx.shadowColor = '#ec4899';
    ctx.shadowBlur = 18;
    ctx.strokeStyle = '#ec4899';
    ctx.lineWidth = 5;
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Nombre principal
    ctx.fillStyle = '#ffffff';
    ctx.font = '800 42px "Segoe UI", Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillText('Valeria Mendez', w / 2, 34);

    // Pill de Status
    const pillW = 280;
    const pillH = 38;
    const pillX = (w - pillW) / 2;
    const pillY = 96;

    ctx.fillStyle = 'rgba(0, 240, 255, 0.12)';
    roundRect(ctx, pillX, pillY, pillW, pillH, 19);
    ctx.fill();
    ctx.strokeStyle = '#00f0ff';
    ctx.lineWidth = 2;
    ctx.stroke();

    // Punto verde esmeralda y texto status
    ctx.fillStyle = '#00ff87';
    ctx.beginPath();
    ctx.arc(pillX + 22, pillY + pillH / 2, 7, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = '#00f0ff';
    ctx.font = '700 20px "Segoe UI", Arial, sans-serif';
    ctx.textAlign = 'left';
    ctx.textBaseline = 'middle';
    ctx.fillText('STATUS: AVAILABLE', pillX + 38, pillY + pillH / 2 + 1);

    // Subtítulo de cargo
    ctx.fillStyle = '#f472b6';
    ctx.font = '600 24px "Segoe UI", Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('• Director', w / 2, 168);
  });
}

/**
 * Alfombra / Tapete de Suelo en frente del cilindro central:
 * [W] WORDVERSE (Exacto a la imagen media_1793083093848_9969c340.jpg)
 */
export function wordverseFloorMatTexture({ w = 1024, h = 420 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    // Fondo negro obsidiana profundo
    ctx.fillStyle = '#06080d';
    ctx.fillRect(0, 0, w, h);

    // Marco exterior de Neón Cian intenso
    ctx.shadowColor = '#00f0ff';
    ctx.shadowBlur = 22;
    ctx.strokeStyle = '#00f0ff';
    ctx.lineWidth = 10;
    roundRect(ctx, 16, 16, w - 32, h - 32, 24);
    ctx.stroke();

    // Línea interior sutil
    ctx.shadowBlur = 0;
    ctx.strokeStyle = 'rgba(0, 240, 255, 0.4)';
    ctx.lineWidth = 3;
    roundRect(ctx, 32, 32, w - 64, h - 64, 16);
    ctx.stroke();

    // Icono cuadrado [W] a la izquierda
    const iconX = 110;
    const iconY = h / 2;
    const iconS = 130;

    ctx.fillStyle = 'rgba(0, 240, 255, 0.18)';
    roundRect(ctx, iconX - iconS / 2, iconY - iconS / 2, iconS, iconS, 20);
    ctx.fill();
    ctx.strokeStyle = '#00f0ff';
    ctx.lineWidth = 6;
    ctx.stroke();

    ctx.fillStyle = '#ffffff';
    ctx.font = '900 86px "Segoe UI", Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('W', iconX, iconY + 6);

    // Tipografía monumental WORDVERSE a la derecha
    ctx.shadowColor = '#00f0ff';
    ctx.shadowBlur = 16;
    ctx.fillStyle = '#ffffff';
    ctx.font = '900 96px "Segoe UI", Arial, sans-serif';
    ctx.textAlign = 'left';
    ctx.letterSpacing = '8px';
    ctx.fillText('WORDVERSE', 230, iconY + 8);
  });
}

/**
 * Textura Monumental del Cilindro Central WORDVERSE (2048x1024).
 * Fondo cian brillante con gráficos de audio, datos binarios y letras gigantes.
 */
export function wordverseCentralDrumTexture({ w = 2048, h = 1024 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    // Degradado vertical de fondo en Cian Cibernético
    const grad = ctx.createLinearGradient(0, 0, 0, h);
    grad.addColorStop(0, '#032030');
    grad.addColorStop(0.2, '#08485e');
    grad.addColorStop(0.5, '#0e697e');
    grad.addColorStop(0.8, '#08485e');
    grad.addColorStop(1, '#032030');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, w, h);

    // Rejilla de datos holográficos
    ctx.strokeStyle = 'rgba(0, 240, 255, 0.22)';
    ctx.lineWidth = 1.5;
    for (let x = 0; x < w; x += 32) {
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke();
    }
    for (let y = 0; y < h; y += 32) {
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
    }

    // Ondas senoidales y visualizador de espectro de audio (Cian y Oro)
    for (let wave = 0; wave < 3; wave++) {
      ctx.strokeStyle = wave === 1 ? '#d4af37' : '#00f0ff';
      ctx.lineWidth = 4;
      ctx.beginPath();
      for (let x = 0; x <= w; x += 10) {
        const y = h * (0.28 + wave * 0.22) + Math.sin(x * 0.02 + wave * 2) * 35;
        if (x === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();
    }

    // Barras de ecualizador digital
    ctx.fillStyle = '#00f0ff';
    for (let x = 20; x < w; x += 40) {
      const bh = 30 + Math.abs(Math.sin(x * 0.05)) * 90;
      ctx.fillRect(x, h * 0.72 - bh, 22, bh);
      ctx.fillRect(x, h * 0.88 - bh * 0.5, 22, bh * 0.5);
    }

    // Texto repetido a lo largo del cilindro (3 repeticiones para 360 grados)
    const segmentW = w / 3;
    for (let i = 0; i < 3; i++) {
      const cx = segmentW * (i + 0.5);

      // Líneas de código y ticker superior
      ctx.fillStyle = 'rgba(255, 255, 255, 0.85)';
      ctx.font = '700 24px "Courier New", monospace';
      ctx.textAlign = 'center';
      ctx.fillText('0x7F8B99A4 · BLOCK #1948291 · AI SYNC OK', cx, 110);
      ctx.fillText('P2P ESCROW ACTIVE · 14,820 NODES ONLINE · 99.99%', cx, 150);

      // Gran letrero central "WORDVERSE"
      ctx.shadowColor = '#00f0ff';
      ctx.shadowBlur = 32;
      ctx.fillStyle = '#ffffff';
      ctx.font = '900 120px "Segoe UI", Arial, sans-serif';
      ctx.letterSpacing = '10px';
      ctx.fillText('WORDVERSE', cx, 480);
      ctx.shadowBlur = 0;

      // Sub-bloques y gráficas inferiores
      ctx.fillStyle = '#00f0ff';
      ctx.font = '700 28px "Segoe UI", Arial, sans-serif';
      ctx.fillText('GLOBAL METAVERSE BUSINESS CORE', cx, 570);

      ctx.fillStyle = 'rgba(212, 175, 55, 0.95)';
      ctx.font = '800 22px "Segoe UI", Arial, sans-serif';
      ctx.fillText('★ OFFICIAL PREMION 3D HUB ★', cx, 615);

      // Bloques de datos inferiores
      ctx.fillStyle = 'rgba(255, 255, 255, 0.7)';
      ctx.font = '600 20px "Courier New", monospace';
      ctx.fillText('TX: 4.8M TPS | LATENCY: 2.1ms | PROTOCOL: V4.2', cx, 930);
    }
  });
}

/**
 * Pantalla Holográfica de Biometría / AI (#OFFERS / APPROVED)
 * para la pared derecha según la imagen de referencia.
 */
export function biometricAiScreenTexture({ w = 1024, h = 1024 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    // Fondo oscuro translúcido con cuadrícula
    ctx.fillStyle = 'rgba(6, 12, 28, 0.9)';
    ctx.fillRect(0, 0, w, h);

    ctx.strokeStyle = 'rgba(0, 240, 255, 0.12)';
    ctx.lineWidth = 1;
    for (let x = 0; x < w; x += 32) {
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke();
    }
    for (let y = 0; y < h; y += 32) {
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
    }

    // Marco exterior con esquinas biseladas
    ctx.strokeStyle = '#00f0ff';
    ctx.lineWidth = 6;
    ctx.strokeRect(16, 16, w - 32, h - 32);

    // Kiosco verde brillante: #OFFERS
    ctx.fillStyle = '#00ff87';
    ctx.shadowColor = '#00ff87';
    ctx.shadowBlur = 20;
    roundRect(ctx, 60, 60, 320, 80, 16);
    ctx.fill();
    ctx.shadowBlur = 0;

    ctx.fillStyle = '#061320';
    ctx.font = '900 48px "Segoe UI", Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('#OFFERS', 220, 118);

    // Kiosco cian: APPROVED
    ctx.fillStyle = '#00f0ff';
    ctx.shadowColor = '#00f0ff';
    ctx.shadowBlur = 20;
    roundRect(ctx, 420, 60, 320, 80, 16);
    ctx.fill();
    ctx.shadowBlur = 0;

    ctx.fillStyle = '#061320';
    ctx.font = '900 42px "Segoe UI", Arial, sans-serif';
    ctx.fillText('APPROVED', 580, 116);

    // Escaneo Biométrico / Red Neuronal (Círculos concéntricos y nodos)
    const bx = w / 2;
    const by = 420;
    for (let r = 40; r <= 180; r += 35) {
      ctx.strokeStyle = 'rgba(0, 240, 255, 0.4)';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(bx, by, r, 0, Math.PI * 2);
      ctx.stroke();
    }

    // Nodos neuronales
    ctx.fillStyle = '#00ff87';
    for (let i = 0; i < 24; i++) {
      const ang = (i / 24) * Math.PI * 2;
      const r = 60 + (i % 4) * 35;
      const nx = bx + Math.cos(ang) * r;
      const ny = by + Math.sin(ang) * r;
      ctx.beginPath();
      ctx.arc(nx, ny, 6, 0, Math.PI * 2);
      ctx.fill();
    }

    // Gráfica de pulso ECG en color ámbar
    ctx.strokeStyle = '#f59e0b';
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.moveTo(60, 720);
    ctx.lineTo(240, 720);
    ctx.lineTo(280, 640);
    ctx.lineTo(320, 800);
    ctx.lineTo(360, 720);
    ctx.lineTo(540, 720);
    ctx.lineTo(580, 620);
    ctx.lineTo(620, 820);
    ctx.lineTo(660, 720);
    ctx.lineTo(w - 60, 720);
    ctx.stroke();

    // Estadísticas
    ctx.fillStyle = '#ffffff';
    ctx.font = '700 28px "Segoe UI", Arial, sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText('BIOMETRIC AUTH: 100% PASSED', 80, 890);
    ctx.fillStyle = '#00ff87';
    ctx.fillText('IDENTITY: ESCROW MULTI-SIG VERIFIED', 80, 940);
  });
}

/**
 * Pantalla Monumental Curva Mezzanine:
 * Gran Mapamundi Táctico con rutas de datos, velas de trading y métricas financieras.
 */
export function curvedCommandCenterMapTexture({ w = 2048, h = 1024 } = {}) {
  return canvasTexture(w, h, (ctx) => {
    // Fondo oscuro
    ctx.fillStyle = '#030b18';
    ctx.fillRect(0, 0, w, h);

    // Cuadrícula táctica
    ctx.strokeStyle = 'rgba(0, 240, 255, 0.12)';
    ctx.lineWidth = 1;
    for (let x = 0; x < w; x += 40) {
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke();
    }
    for (let y = 0; y < h; y += 40) {
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
    }

    // Mapamundi con puntos de luz cian
    const continents = [
      { cx: 0.22, cy: 0.35, rx: 180, ry: 110 }, // Norteamérica
      { cx: 0.32, cy: 0.68, rx: 110, ry: 140 }, // Sudamérica
      { cx: 0.52, cy: 0.30, rx: 120, ry: 80 },  // Europa
      { cx: 0.55, cy: 0.58, rx: 130, ry: 150 }, // África
      { cx: 0.74, cy: 0.36, rx: 220, ry: 140 }, // Asia
      { cx: 0.84, cy: 0.74, rx: 100, ry: 80 },  // Oceanía
    ];

    ctx.fillStyle = '#00f0ff';
    continents.forEach(c => {
      for (let i = 0; i < 220; i++) {
        const ang = Math.random() * Math.PI * 2;
        const d = Math.sqrt(Math.random());
        const x = c.cx * w + Math.cos(ang) * c.rx * d;
        const y = c.cy * h + Math.sin(ang) * c.ry * d;
        ctx.fillRect(x, y, 2.5, 2.5);
      }
    });

    // Rutas aéreas / de datos intercontinentales curvas
    ctx.strokeStyle = '#00f0ff';
    ctx.lineWidth = 2.5;
    const routes = [
      [[0.22 * w, 0.35 * h], [0.52 * w, 0.30 * h]],
      [[0.52 * w, 0.30 * h], [0.74 * w, 0.36 * h]],
      [[0.22 * w, 0.35 * h], [0.32 * w, 0.68 * h]],
      [[0.74 * w, 0.36 * h], [0.84 * w, 0.74 * h]],
    ];
    routes.forEach(([p1, p2]) => {
      ctx.beginPath();
      ctx.moveTo(p1[0], p1[1]);
      const midX = (p1[0] + p2[0]) / 2;
      const midY = Math.min(p1[1], p2[1]) - 90;
      ctx.quadraticCurveTo(midX, midY, p2[0], p2[1]);
      ctx.stroke();
    });

    // Velas de Trading a la izquierda y derecha
    for (let i = 0; i < 18; i++) {
      const up = i % 3 !== 0;
      ctx.fillStyle = up ? '#00ff87' : '#ef4444';
      ctx.strokeStyle = ctx.fillStyle;
      ctx.lineWidth = 2;
      const x = 50 + i * 22;
      const y = 300 + Math.sin(i * 0.8) * 80;
      const bh = 20 + Math.random() * 40;
      ctx.beginPath();
      ctx.moveTo(x + 7, y - 15);
      ctx.lineTo(x + 7, y + bh + 15);
      ctx.stroke();
      ctx.fillRect(x, y, 14, bh);
    }

    // Cabecera superior
    ctx.fillStyle = '#00f0ff';
    ctx.font = '900 48px "Segoe UI", Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('GLOBAL METAVERSE REAL-TIME MONITOR', w / 2, 70);

    ctx.fillStyle = '#d4af37';
    ctx.font = '700 24px "Segoe UI", Arial, sans-serif';
    ctx.fillText('• 24H LIQUIDITY: $48.9M • P2P ESCROW: $12.4M • NODES: 99.98% ACTIVE', w / 2, 115);
  });
}
