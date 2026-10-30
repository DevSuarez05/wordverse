/**
 * Motor de Audio Sintetizado Web Audio API (Zero Dependencias, Cero Latencia).
 * Genera efectos de sonido cinematográficos futuristas estilo GTA VI / Cyberpunk.
 * Incluye simulación acústica espacial 3D y aislamiento sonoro en salas privadas.
 */

let ctx = null;
let masterGain = null;
let acousticFilter = null;
let currentZone = 'atrium'; // 'atrium' | 'boardroom' | 'mezzanine'
let atmosphereStarted = false;
let atmoOsc = null;
let atmoGain = null;
let boardroomOsc = null;
let boardroomGain = null;

function getContext() {
  if (!ctx) {
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (AudioCtx) {
      ctx = new AudioCtx();
      masterGain = ctx.createGain();
      masterGain.gain.setValueAtTime(0.85, ctx.currentTime);

      acousticFilter = ctx.createBiquadFilter();
      acousticFilter.type = 'lowpass';
      acousticFilter.frequency.setValueAtTime(4500, ctx.currentTime);
      acousticFilter.Q.setValueAtTime(1.0, ctx.currentTime);

      acousticFilter.connect(masterGain);
      masterGain.connect(ctx.destination);
    }
  }
  if (ctx && ctx.state === 'suspended') {
    ctx.resume().catch(() => {});
  }
  return ctx;
}

// Desbloquear AudioContext en la primera interacción de usuario
if (typeof window !== 'undefined') {
  const unlock = () => {
    getContext();
    window.removeEventListener('pointerdown', unlock);
    window.removeEventListener('keydown', unlock);
  };
  window.addEventListener('pointerdown', unlock, { once: true });
  window.addEventListener('keydown', unlock, { once: true });
}

/** Chime dual elegante de llegada de ascensor ejecutivo (D5 587Hz -> A5 880Hz). */
export function playElevatorChime() {
  try {
    const ac = getContext();
    if (!ac) return;
    const now = ac.currentTime;

    const osc1 = ac.createOscillator();
    const osc2 = ac.createOscillator();
    const gainNode = ac.createGain();

    osc1.type = 'sine';
    osc2.type = 'sine';

    osc1.frequency.setValueAtTime(587.33, now); // D5
    osc2.frequency.setValueAtTime(880.00, now + 0.16); // A5

    gainNode.gain.setValueAtTime(0.09, now);
    gainNode.gain.exponentialRampToValueAtTime(0.0001, now + 1.2);

    osc1.connect(gainNode);
    osc2.connect(gainNode);
    gainNode.connect(acousticFilter || ac.destination);

    osc1.start(now);
    osc1.stop(now + 0.22);
    osc2.start(now + 0.16);
    osc2.stop(now + 1.2);
  } catch (_) {}
}

/** Sonido sutil de apertura o cierre de compuerta magnética. */
export function playDoorServo() {
  try {
    const ac = getContext();
    if (!ac) return;
    const now = ac.currentTime;

    const osc = ac.createOscillator();
    const gain = ac.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(120, now);
    osc.frequency.exponentialRampToValueAtTime(240, now + 0.35);

    gain.gain.setValueAtTime(0.03, now);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.4);

    osc.connect(gain);
    gain.connect(acousticFilter || ac.destination);

    osc.start(now);
    osc.stop(now + 0.4);
  } catch (_) {}
}

/** Chirp holográfico al interactuar o activar un hotspot / botón. */
export function playHoloClick() {
  try {
    const ac = getContext();
    if (!ac) return;
    const now = ac.currentTime;

    const osc = ac.createOscillator();
    const gain = ac.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(1400, now);
    osc.frequency.exponentialRampToValueAtTime(2800, now + 0.08);

    gain.gain.setValueAtTime(0.06, now);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.12);

    osc.connect(gain);
    gain.connect(acousticFilter || ac.destination);

    osc.start(now);
    osc.stop(now + 0.12);
  } catch (_) {}
}

/** Tono suave de cambio de modo de cámara. */
export function playCameraSwitch() {
  try {
    const ac = getContext();
    if (!ac) return;
    const now = ac.currentTime;

    const osc = ac.createOscillator();
    const gain = ac.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(900, now);
    osc.frequency.exponentialRampToValueAtTime(1200, now + 0.09);

    gain.gain.setValueAtTime(0.05, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.15);

    osc.connect(gain);
    gain.connect(ac.destination);

    osc.start(now);
    osc.stop(now + 0.15);
  } catch (_) {}
}

/**
 * Sonido sintetizado de pisada reactiva según la superficie arquitectónica (Mármol vs Alfombra vs Escalera).
 */
export function playFootstep(surface = 'marble') {
  try {
    const ac = getContext();
    if (!ac) return;
    const now = ac.currentTime;

    const osc = ac.createOscillator();
    const gain = ac.createGain();

    if (surface === 'marble') {
      osc.type = 'triangle';
      const pitch = 380 + Math.random() * 80;
      osc.frequency.setValueAtTime(pitch, now);
      osc.frequency.exponentialRampToValueAtTime(120, now + 0.045);

      gain.gain.setValueAtTime(0.022, now);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.05);
    } else if (surface === 'carpet') {
      osc.type = 'sine';
      osc.frequency.setValueAtTime(90, now);
      osc.frequency.exponentialRampToValueAtTime(45, now + 0.06);

      gain.gain.setValueAtTime(0.015, now);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.07);
    } else if (surface === 'stairs') {
      osc.type = 'triangle';
      const pitch = 240 + Math.random() * 40;
      osc.frequency.setValueAtTime(pitch, now);
      osc.frequency.exponentialRampToValueAtTime(80, now + 0.05);

      gain.gain.setValueAtTime(0.025, now);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.055);
    }

    osc.connect(gain);
    gain.connect(acousticFilter || ac.destination);

    osc.start(now);
    osc.stop(now + 0.07);
  } catch (_) {}
}

/** Inicia la atmósfera acústica de sala corporativa y reverberación de aire de forma no intrusiva. */
export function startAtmosphere() {
  if (atmosphereStarted) return;
  try {
    const ac = getContext();
    if (!ac) return;
    atmosphereStarted = true;
    const now = ac.currentTime;

    // Sub-hum suave de climatización y atrio (65Hz)
    atmoOsc = ac.createOscillator();
    atmoGain = ac.createGain();
    atmoOsc.type = 'sine';
    atmoOsc.frequency.setValueAtTime(65, now);
    atmoGain.gain.setValueAtTime(0.0001, now);
    atmoGain.gain.linearRampToValueAtTime(0.004, now + 3.0);
    atmoOsc.connect(atmoGain);
    atmoGain.connect(acousticFilter || ac.destination);
    atmoOsc.start(now);

    // Hum seguro de The Boardroom VIP (110Hz con filtro sutil)
    boardroomOsc = ac.createOscillator();
    boardroomGain = ac.createGain();
    boardroomOsc.type = 'sine';
    boardroomOsc.frequency.setValueAtTime(110, now);
    boardroomGain.gain.setValueAtTime(0.0, now);
    boardroomOsc.connect(boardroomGain);
    boardroomGain.connect(ac.destination);
    boardroomOsc.start(now);
  } catch (_) {}
}

/**
 * Actualiza la simulación acústica espacial en tiempo real según la posición del avatar y la sala activa.
 * Aplica aislamiento acústico (filtro paso bajo) en The Boardroom y modula el balance estereofónico.
 */
export function updateSpatialAudio(playerX, playerZ, inBoardroom) {
  try {
    const ac = getContext();
    if (!ac || !acousticFilter) return;
    const now = ac.currentTime;

    if (inBoardroom) {
      if (currentZone !== 'boardroom') {
        currentZone = 'boardroom';
        // Aislamiento acústico de junta confidencial: apagar ruidos agudos del exterior
        acousticFilter.frequency.setTargetAtTime(680, now, 0.4);
        if (atmoGain) atmoGain.gain.setTargetAtTime(0.001, now, 0.5);
        if (boardroomGain) boardroomGain.gain.setTargetAtTime(0.006, now, 0.5);
      }
    } else {
      if (currentZone !== 'atrium') {
        currentZone = 'atrium';
        // Atrio público abierto: espectro acústico amplio y reverberante
        acousticFilter.frequency.setTargetAtTime(5200, now, 0.4);
        if (atmoGain) atmoGain.gain.setTargetAtTime(0.004, now, 0.5);
        if (boardroomGain) boardroomGain.gain.setTargetAtTime(0.0, now, 0.5);
      }
    }
  } catch (_) {}
}

/** Acorde cristalino armónico cuando se activa el Copiloto Holográfico Nexus AI (C6 + E6 + G6). */
export function playAiWakeChime() {
  try {
    const ac = getContext();
    if (!ac) return;
    const now = ac.currentTime;
    const freqs = [1046.5, 1318.5, 1567.98];
    freqs.forEach((f, i) => {
      const osc = ac.createOscillator();
      const gain = ac.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(f, now + i * 0.06);
      gain.gain.setValueAtTime(0.04, now + i * 0.06);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + i * 0.06 + 0.55);
      osc.connect(gain);
      gain.connect(acousticFilter || ac.destination);
      osc.start(now + i * 0.06);
      osc.stop(now + i * 0.06 + 0.55);
    });
  } catch (_) {}
}

let aiVoiceMuted = false;
let fallbackSpeechTimer = null;

export function setNexusAiVoiceMuted(muted) {
  aiVoiceMuted = !!muted;
  if (aiVoiceMuted && typeof window !== 'undefined' && window.speechSynthesis) {
    try { window.speechSynthesis.cancel(); } catch (_) {}
  }
  return aiVoiceMuted;
}

export function isNexusAiVoiceMuted() {
  return aiVoiceMuted;
}

/**
 * Síntesis de voz neural en tiempo real para el Copiloto Holográfico Nexus AI.
 * Dispara callbacks onStart/onEnd para sincronizar el anillo de onda de voz 3D y el ecualizador HUD.
 */
export function speakNexusAi(text, { onStart, onEnd } = {}) {
  if (fallbackSpeechTimer) {
    clearTimeout(fallbackSpeechTimer);
    fallbackSpeechTimer = null;
  }
  playAiWakeChime();
  if (onStart) onStart();

  const estimatedMs = Math.min(Math.max(text.length * 48, 2200), 7500);
  fallbackSpeechTimer = setTimeout(() => {
    if (onEnd) onEnd();
  }, estimatedMs);

  if (aiVoiceMuted || typeof window === 'undefined' || !window.speechSynthesis) {
    return;
  }

  try {
    window.speechSynthesis.cancel();
    const utter = new SpeechSynthesisUtterance(text);
    utter.lang = 'es-ES';
    utter.rate = 1.05;
    utter.pitch = 1.04;
    const voices = window.speechSynthesis.getVoices?.() || [];
    const esVoice = voices.find(v => v.lang && v.lang.toLowerCase().startsWith('es') && (v.name.includes('Natural') || v.name.includes('Google') || v.name.includes('Microsoft')))
      || voices.find(v => v.lang && v.lang.toLowerCase().startsWith('es'));
    if (esVoice) utter.voice = esVoice;
    utter.onend = () => {
      if (fallbackSpeechTimer) {
        clearTimeout(fallbackSpeechTimer);
        fallbackSpeechTimer = null;
      }
      if (onEnd) onEnd();
    };
    window.speechSynthesis.speak(utter);
  } catch (_) {}
}
