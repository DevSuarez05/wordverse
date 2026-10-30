import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import {
  isNexusAiVoiceMuted, playAiWakeChime, playCameraSwitch, playFootstep, playHoloClick,
  setNexusAiVoiceMuted, speakNexusAi, startAtmosphere, updateSpatialAudio,
} from './audio.js?v=20261029_v6';
import { createAvatar } from './avatars.js?v=20261029_v6';
import { createBridge } from './bridge.js?v=20261029_v6';
import {
  BOUND, ELEVATOR, MEZZANINE_Y, SEATS, SPAWN, STAIRS, WORLD_SCALE as S,
  cameraRelativeMove, getStairHeight, isInBoardroom, isInStairs,
  isNearBoardroomExit, isNearKiosk, isNearPrivatePortal, isNearReceptionDesk, nearestHotspot, resolve,
} from './physics.js?v=20261029_v6';
import { buildWorld } from './world.js?v=20261029_v7';
import { BOARDROOM_SLIDES } from './textures.js?v=20261029_v6';

const WALK = 0.22; // normalizado / s  (2.2 m/s)
const RUN = 0.4;
const SUB_ROOM_ACCENT = {
  'Shest Café': '#d4af37', P2P: '#4ade80', Escrow: '#fbbf24', Negocios: '#c084fc', Networking: '#60a5fa',
};

const DEFAULT_HOTSPOTS = [
  { kind: 'networking', code: 'HOTSPOT 01', title: 'Networking', subtitle: 'Sala Pública • SHES\'T', x: -0.6, z: -0.45, color: '#22d3ee' },
  { kind: 'createMeeting', code: 'HOTSPOT 02', title: 'Crear reunión', subtitle: 'Empresas Mundiales', x: 0.0, z: -0.65, color: '#38bdf8' },
  { kind: 'qr', code: 'HOTSPOT 03', title: 'QR', subtitle: 'Kiosco • Compañía Privada', x: 0.6, z: -0.45, color: '#fbbf24' },
  { kind: 'p2p', code: 'HOTSPOT 04', title: 'P2P', subtitle: 'Mercado Shest', x: -0.68, z: 0.2, color: '#4ade80' },
  { kind: 'escrow', code: 'HOTSPOT 05', title: 'ESCROW', subtitle: 'Recepción WordVerse', x: 0.68, z: 0.2, color: '#fbbf24' },
  { kind: 'myProfile', code: 'HOTSPOT 06', title: 'Mi perfil', subtitle: 'Tarjeta VR', x: -0.45, z: 0.68, color: '#22d3ee' },
  { kind: 'exit', code: 'HOTSPOT 07', title: 'Salir', subtitle: 'Portal Shest Hub', x: 0.45, z: 0.68, color: '#f87171' },
];

const canvas = document.getElementById('c');
const promptEl = document.getElementById('prompt');
const loadingEl = document.getElementById('loading');
const actionBtn = document.getElementById('action-btn');
const btnRoomPublic = document.getElementById('btn-room-public');
const btnRoomPrivate = document.getElementById('btn-room-private');
const presenterBar = document.getElementById('boardroom-presenter-bar');
const btnSlidePrev = document.getElementById('btn-slide-prev');
const btnSlideNext = document.getElementById('btn-slide-next');
const slideTitleLabel = document.getElementById('slide-title-label');
const btnAiMinutes = document.getElementById('btn-ai-minutes');
const nexusAiBtn = document.getElementById('nexus-ai-btn');
const nexusAiPanel = document.getElementById('nexus-ai-panel');
const btnAiMute = document.getElementById('btn-ai-mute');
const btnAiClose = document.getElementById('btn-ai-close');
const aiResponseText = document.getElementById('ai-response-text');
const aiQueryForm = document.getElementById('ai-query-form');
const aiQueryInput = document.getElementById('ai-query-input');
const aiMinutesBox = document.getElementById('ai-minutes-box');
const aiMinutesContent = document.getElementById('ai-minutes-content');
const btnCopyMinutes = document.getElementById('btn-copy-minutes');
const btnDownloadMinutes = document.getElementById('btn-download-minutes');
const kioskBtn = document.getElementById('kiosk-btn');
const kioskPanel = document.getElementById('kiosk-panel');
const btnKioskClose = document.getElementById('btn-kiosk-close');
const kioskProdName = document.getElementById('kiosk-prod-name');
const kioskProdPrice = document.getElementById('kiosk-prod-price');
const kioskProdDesc = document.getElementById('kiosk-prod-desc');
const kioskProdMeta = document.getElementById('kiosk-prod-meta');
const btnKioskBuy = document.getElementById('btn-kiosk-buy');
const btnKioskVendor = document.getElementById('btn-kiosk-vendor');
const kioskReceiptBox = document.getElementById('kiosk-receipt-box');
const radarExecName = document.getElementById('radar-exec-name');
const radarExecMatch = document.getElementById('radar-exec-match');
const radarExecTopic = document.getElementById('radar-exec-topic');
const btnRadarConnect = document.getElementById('btn-radar-connect');
const perfBadge = document.getElementById('perf-badge');

const holoCardPanel = document.getElementById('holo-card-panel');
const holoCardBadge = document.getElementById('holo-card-badge');
const holoCardName = document.getElementById('holo-card-name');
const holoCardTitle = document.getElementById('holo-card-title');
const holoCardStatus = document.getElementById('holo-card-status-text');
const holoMetricVerif = document.getElementById('holo-metric-verif');
const holoMetricRep = document.getElementById('holo-metric-rep');
const holoMetricWallet = document.getElementById('holo-metric-wallet');
const holoMetricLang = document.getElementById('holo-metric-lang');
const btnHoloClose = document.getElementById('btn-holo-close');
const btnHoloChat = document.getElementById('btn-holo-chat');
const btnHoloWave = document.getElementById('btn-holo-wave');
const btnHoloEscrow = document.getElementById('btn-holo-escrow');
let currentHoloAvatar = null;

const hudWalletPill = document.getElementById('hud-wallet-pill');
const hudWalletAmount = document.getElementById('hud-wallet-amount');
const btnKioskQr = document.getElementById('btn-kiosk-qr');
const kioskQrBox = document.getElementById('kiosk-qr-box');
const kioskQrCanvas = document.getElementById('kiosk-qr-canvas');
const kioskTrc20Addr = document.getElementById('kiosk-trc20-addr');
const btnCloseQrBox = document.getElementById('btn-close-qr-box');
const btnCopyTrc20 = document.getElementById('btn-copy-trc20');
const btnKioskQrConfirm = document.getElementById('btn-kiosk-qr-confirm');
const holoToastContainer = document.getElementById('holo-toast-container');
const btnFastTravel = document.getElementById('btn-fast-travel');
const teleportPanel = document.getElementById('teleport-panel');
const teleportOverlay = document.getElementById('teleport-overlay');
const btnTeleportClose = document.getElementById('btn-teleport-close');
let localWalletBalance = 5420.0;

function showHoloToast({ title, message, icon = '💼', duration = 4000 }) {
  if (!holoToastContainer) return;
  const toast = document.createElement('div');
  toast.className = 'holo-toast';
  toast.innerHTML = `
    <div class="holo-toast-icon">${icon}</div>
    <div class="holo-toast-content">
      <div class="holo-toast-title">${title}</div>
      <div class="holo-toast-msg">${message}</div>
    </div>
  `;
  holoToastContainer.appendChild(toast);
  playHoloClick();

  setTimeout(() => {
    toast.style.transition = 'all 0.35s ease';
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(12px) scale(0.92)';
    setTimeout(() => toast.remove(), 350);
  }, duration);
}

function updateWalletDisplay(balance) {
  localWalletBalance = typeof balance === 'number' ? balance : localWalletBalance;
  if (hudWalletAmount) {
    hudWalletAmount.textContent = `${Math.round(localWalletBalance).toLocaleString()} USDT`;
  }
  if (hudWalletPill) {
    hudWalletPill.classList.remove('flash-gain');
    void hudWalletPill.offsetWidth;
    hudWalletPill.classList.add('flash-gain');
  }
}

const bridge = createBridge();

// ------------------------------------------------------------------ renderer
let renderer;
try {
  renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: 'high-performance' });
} catch (e) {
  bridge.send({ type: 'error', message: 'WebGL no disponible: ' + e.message });
  loadingEl.textContent = 'WebGL no disponible';
  throw e;
}
// Optimización de rendimiento para 60 FPS estables (DPR controlado y antialiasing eficiente)
renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.25));
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.05;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;

const scene = new THREE.Scene();
// Paleta Oficial PREMION: Negro Obsidiana (#0A0A0C)
scene.background = new THREE.Color(0x0a0a0c);
scene.fog = new THREE.FogExp2(0x0a0a0c, 0.007);

// Iluminación IBL PBR con acentos exactos de la paleta oficial (Oro #D4AF37, Cian #00F0FF, Púrpura #7B2CBF)
try {
  const pmrem = new THREE.PMREMGenerator(renderer);
  pmrem.compileEquirectangularShader();
  const envScene = new THREE.Scene();
  envScene.background = new THREE.Color(0x060608);
  const eL1 = new THREE.DirectionalLight(0xfff6e5, 1.2);
  eL1.position.set(4, 12, 6);
  envScene.add(eL1);
  const eL2 = new THREE.DirectionalLight(0x00f0ff, 0.85);
  eL2.position.set(-6, 8, -4);
  envScene.add(eL2);
  const eL3 = new THREE.DirectionalLight(0x7b2cbf, 0.65);
  eL3.position.set(0, -6, 0);
  envScene.add(eL3);

  // Paneles emisivos de estudio de lujo (Oro, Neón Cian y Metrópolis Nocturna)
  const softBox = new THREE.Mesh(
    new THREE.BoxGeometry(10, 2.5, 0.4),
    new THREE.MeshBasicMaterial({ color: 0xd4af37 })
  );
  softBox.position.set(0, 11, -3);
  envScene.add(softBox);

  const neonBarCyan = new THREE.Mesh(
    new THREE.BoxGeometry(0.3, 8, 0.3),
    new THREE.MeshBasicMaterial({ color: 0x00f0ff })
  );
  neonBarCyan.position.set(-8, 5, 2);
  envScene.add(neonBarCyan);

  const neonBarPurple = new THREE.Mesh(
    new THREE.BoxGeometry(0.3, 8, 0.3),
    new THREE.MeshBasicMaterial({ color: 0x7b2cbf })
  );
  neonBarPurple.position.set(8, 5, -2);
  envScene.add(neonBarPurple);

  const envRt = pmrem.fromScene(envScene, 0.04);
  scene.environment = envRt.texture;
} catch (e) {
  console.warn('IBL fallback:', e);
}

const camera = new THREE.PerspectiveCamera(54, 1, 0.1, 120);

const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
// Buffer de bloom optimizado a 256x256 para cero caídas de FPS
const bloom = new UnrealBloomPass(new THREE.Vector2(256, 256), 0.18, 0.40, 0.88);
composer.addPass(bloom);
composer.addPass(new OutputPass());
let useBloom = true;

function resize() {
  const w = window.innerWidth;
  const h = window.innerHeight;
  renderer.setSize(w, h, false);
  composer.setSize(w, h);
  camera.aspect = w / Math.max(1, h);
  camera.updateProjectionMatrix();
}
window.addEventListener('resize', resize);
resize();

// --------------------------------------------------------------------- estado
let hotspots = DEFAULT_HOTSPOTS;
let world = buildWorld(scene, { hotspots });
const player = { x: SPAWN.x, y: 0, z: SPAWN.z, rot: 0, moving: 0, avatar: null };
const remotes = new Map();
const cam = { yaw: 0, pitch: 0.32, dist: 5.2, zoom: 1, dartYaw: 0, pos: new THREE.Vector3(0, 3.2, 5.8) };
const CAM_MODES = [
  { id: 'ots', name: 'OTS (GTA V)', desc: 'Tercera persona hombro derecho' },
  { id: 'wide', name: 'PANORÁMICA 4K', desc: 'Gran angular cinemático del Atrio y Mezzanine' },
  { id: 'fpv', name: 'PRIMERA PERSONA (FPV)', desc: 'Visión subjetiva inmersiva a nivel de ojos' },
  { id: 'drone', name: 'DRONE CINEMÁTICO 360°', desc: 'Órbita panorámica autónoma' },
];
let camModeIndex = 0;
let droneOrbitYaw = 0;
const camBtn = document.getElementById('cam-btn');

function cycleCameraMode() {
  camModeIndex = (camModeIndex + 1) % CAM_MODES.length;
  const mode = CAM_MODES[camModeIndex];
  playCameraSwitch();
  if (camBtn) {
    const shortName = mode.id.toUpperCase();
    camBtn.textContent = `📷 CAM: ${shortName} · [V]`;
  }
  promptEl.textContent = `Modo Cámara: ${mode.name} · ${mode.desc}`;
  promptEl.classList.add('show');
  promptTimer = 2.8;
}

if (camBtn) {
  camBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    cycleCameraMode();
  });
}

const keys = new Set();
let joy = { x: 0, y: 0 };
let near = null;
let nearElevator = false;
let elevatorPlayerInside = false;
let wasInsideElev = false;
let autoDepartTimer = 0;
let lastSent = 0;
let wasMoving = false;
let footstepTimer = 0;
let ready = false;

let localUserInfo = { name: 'Daniel', company: 'Shest Labs' };

function makePlayer(u) {
  localUserInfo = {
    name: u.name || 'Daniel',
    company: u.company || 'Shest Labs',
  };
  if (player.avatar) {
    scene.remove(player.avatar.group);
    player.avatar.dispose();
  }
  player.avatar = createAvatar({
    id: u.id || 'local', name: u.name || 'Tú', company: u.company || '', status: u.status || 'Disponible',
    colorHex: u.color ?? 0x22d3ee, isLocal: true,
  });
  scene.add(player.avatar.group);
  player.x = u.x ?? SPAWN.x;
  player.y = u.y ?? 0;
  player.z = u.z ?? SPAWN.z;
  cam.yaw = 0;
  cam.dartYaw = 0;
}

// -------------------------------------------------------------------- eventos
const handlers = {
  init(m) {
    if (Array.isArray(m.hotspots) && m.hotspots.length) {
      hotspots = m.hotspots;
      scene.remove(world.root);
      world = buildWorld(scene, { hotspots });
    }
    makePlayer(m.local || {});
    syncRemotes(m.remotes || []);
    if (m.subRoom) handlers.subRoom({ name: m.subRoom });
    ready = true;
    loadingEl.style.display = 'none';
  },
  remotes(m) { syncRemotes(m.list || []); },
  input(m) { joy = { x: m.x || 0, y: m.y || 0 }; },
  camera(m) {
    if (typeof m.yaw === 'number') cam.dartYaw = m.yaw;
    if (typeof m.zoom === 'number') cam.zoom = m.zoom;
    if (typeof m.pitch === 'number') cam.pitch = THREE.MathUtils.clamp(m.pitch, 0.04, 1.15);
  },
  subRoom(m) {
    world.setAccent(SUB_ROOM_ACCENT[m.name] || '#d4af37');
    if (m.name === 'Sala Privada') {
      if (player.x <= 1.8) {
        goToBoardroom({ viaPortal: false, notifyFlutter: false });
      }
    } else if (m.name === 'Sala Principal' || m.name === 'Sala Pública') {
      if (player.x > 1.8) {
        exitBoardroomToEntryPoint({ notifyFlutter: false });
      }
    }
  },
  emote(m) { player.avatar?.showEmote(m.text, performance.now() / 1000); },
  boardroomSlide(m) {
    if (typeof m.index === 'number') changeBoardroomSlide(m.index);
    else if (m.action === 'prev') changeBoardroomSlide('prev');
    else changeBoardroomSlide('next');
  },
  openNexusAi(m) {
    openNexusAiPanel(m?.action || null);
  },
  openKiosk(m) {
    openKioskPanel(typeof m?.productIndex === 'number' ? m.productIndex : 0);
    if (m?.autoBuy) buyKioskProductEscrow();
  },
  teleport(m) {
    if (m?.zone) {
      teleportTo(m.zone);
    } else if (typeof m?.x === 'number' && typeof m?.z === 'number') {
      if (teleportOverlay) teleportOverlay.classList.add('active');
      if (playerSitting) standUp();
      player.x = m.x;
      player.z = m.z;
      player.y = m.y ?? player.y;
      player.rot = m.rot ?? player.rot;
      player.vy = 0;
      player.onGround = true;
      cam.pos.set(player.x * S, player.y + 2.0, player.z * S + 3.8);
      bridge.send({ type: 'moved', x: player.x, z: player.z, rot: player.rot, moving: false });
      setTimeout(() => {
        if (teleportOverlay) teleportOverlay.classList.remove('active');
      }, 180);
    }
  },
  speaking(m) {
    const isSpeaking = m.isSpeaking === true;
    if (m.userId === player.avatar?.id || m.userId === 'local' || m.userId === localUserInfo.id) {
      player.avatar?.setSpeaking(isSpeaking);
    } else {
      const r = remotes.get(m.userId);
      r?.avatar?.setSpeaking(isSpeaking);
    }
  },
  walletUpdated(m) {
    updateWalletDisplay(m.balance);
  },
  notification(m) {
    showHoloToast({
      title: m.title || 'WordVerse Notificación',
      message: m.message || '',
      icon: m.icon || '💼',
      duration: m.duration || 4500,
    });
  },
};
bridge.onMessage((m) => handlers[m.type]?.(m));

function syncRemotes(list) {
  const ids = new Set();
  for (const r of list) {
    ids.add(r.id);
    let e = remotes.get(r.id);
    if (!e) {
      const avatar = createAvatar({ id: r.id, name: r.name, company: r.company, status: r.status, colorHex: r.color });
      avatar.group.position.set(r.x * S, 0, r.z * S);
      if (avatar.plate) avatar.plate.visible = false;
      scene.add(avatar.group);
      e = { avatar, key: '', tx: r.x, tz: r.z, rot: r.rot || 0, trot: r.rot || 0, moving: false, emote: null };
      remotes.set(r.id, e);
    }
    const key = `${r.name}|${r.company}|${r.status}`;
    if (key !== e.key) {
      if (e.key) e.avatar.setPlate({ name: r.name, company: r.company, status: r.status });
      e.key = key;
    }
    e.tx = r.x; e.tz = r.z; e.trot = r.rot || 0; e.moving = !!r.moving;
    if (r.emote && r.emote !== e.emote) e.avatar.showEmote(r.emote, performance.now() / 1000);
    e.emote = r.emote || null;
  }
  for (const [id, e] of remotes) {
    if (!ids.has(id)) {
      scene.remove(e.avatar.group);
      e.avatar.dispose();
      remotes.delete(id);
    }
  }
}

// ---------------------------------------------------------------------- input
function changeBoardroomSlide(deltaOrIndex) {
  playHoloClick();
  let slide;
  if (typeof deltaOrIndex === 'number') {
    if (deltaOrIndex >= 0 && deltaOrIndex <= 3) {
      slide = world.setBoardroomSlide(deltaOrIndex);
    } else {
      slide = deltaOrIndex > 0 ? world.nextBoardroomSlide() : world.prevBoardroomSlide();
    }
  } else if (deltaOrIndex === 'prev') {
    slide = world.prevBoardroomSlide();
  } else {
    slide = world.nextBoardroomSlide();
  }
  const curIdx = world.getBoardroomSlide ? world.getBoardroomSlide() : 0;
  if (slideTitleLabel && slide) {
    slideTitleLabel.textContent = `SLIDE ${curIdx + 1}/4: ${slide.title.toUpperCase()}`;
  }
  flashPrompt(`📊 Presentación: ${slide.title} (${slide.subtitle})`);
  bridge.send({ type: 'boardroomSlideChanged', index: curIdx, title: slide?.title });
  return slide;
}

if (btnSlidePrev) {
  btnSlidePrev.addEventListener('click', (e) => {
    e.stopPropagation();
    changeBoardroomSlide('prev');
  });
}
if (btnSlideNext) {
  btnSlideNext.addEventListener('click', (e) => {
    e.stopPropagation();
    changeBoardroomSlide('next');
  });
}

// =====================================================================
// COPILOTO HOLOGRÁFICO "NEXUS AI" Y GENERADOR DE MINUTAS E2EE (FASE 4)
// =====================================================================
let lastGeneratedMinutesText = '';

function nexusSay(text) {
  if (aiResponseText) {
    aiResponseText.textContent = text;
  }
  speakNexusAi(text, {
    onStart: () => world.setNexusAiSpeaking?.(true),
    onEnd: () => world.setNexusAiSpeaking?.(false),
  });
}

let currentMinutesLanguage = 'es'; // 'es' | 'en' | 'dual'

function updateMinutesLangButtons() {
  const btnEs = document.getElementById('btn-min-lang-es');
  const btnEn = document.getElementById('btn-min-lang-en');
  const btnDual = document.getElementById('btn-min-lang-dual');
  if (btnEs) btnEs.classList.toggle('active', currentMinutesLanguage === 'es');
  if (btnEn) btnEn.classList.toggle('active', currentMinutesLanguage === 'en');
  if (btnDual) btnDual.classList.toggle('active', currentMinutesLanguage === 'dual');
}

function generateBoardroomMinutes(lang = currentMinutesLanguage) {
  currentMinutesLanguage = lang;
  updateMinutesLangButtons();

  const curIdx = world.getBoardroomSlide ? world.getBoardroomSlide() : 0;
  const curSlide = BOARDROOM_SLIDES[curIdx] || BOARDROOM_SLIDES[0];
  const dateStr = new Date().toISOString().slice(0, 10);
  const participantsEs = [
    `${localUserInfo.name} (${localUserInfo.company || 'Ejecutivo Principal'})`,
    'Andrés Morales (Andes Capital · Socio Fundador)',
    'Carlos Mendoza (Nova Pay · Director General)',
    'Elena Rostova (VP Global Escrow)',
  ];
  const participantsEn = [
    `${localUserInfo.name} (${localUserInfo.company || 'Lead Executive'})`,
    'Andrés Morales (Andes Capital · Founding Partner)',
    'Carlos Mendoza (Nova Pay · Managing Director)',
    'Elena Rostova (VP Global Escrow)',
  ];

  const minutesEs = [
    `# MINUTA EJECUTIVA CONFIDENCIAL — WORDVERSE NEXUS VIP`,
    `Fecha: ${dateStr} | Sala: PREMION VIP Boardroom (E2EE)`,
    `Foco Activo: Slide ${curIdx + 1}/4 — ${curSlide.title} (${curSlide.subtitle})`,
    `Hash Auditoría: 0x9F8E...4C2A (Verificado en Red TRC20)`,
    ``,
    `## 1. PARTICIPANTES VERIFICADOS`,
    ...participantsEs.map(p => `- ${p}`),
    ``,
    `## 2. ACUERDOS Y RESOLUCIONES DE JUNTA`,
    `- [APROBADO] Liquidación P2P Q4 certificada en $48,500,000 USDT (+24.6% vs Q3) con 0% default.`,
    `- [APROBADO] Despliegue de bóveda Multi-Firma 3-de-5 con custodia distribuida y SLA 99.98%.`,
    `- [APROBADO] Asignación de Ronda Sindicada 2026 ($12.5M Liquidez, $5M Reserva, $3.5M R&D IA).`,
    ``,
    `## 3. COMPROMISOS Y TAREAS (ACTION ITEMS)`,
    `1. ${localUserInfo.name}: Firmar llave maestra #1 de liberación de Escrow institucional.`,
    `2. Andrés Morales: Ejecutar auditoría trimestral de nodos validadores LatAm.`,
    `3. Carlos Mendoza: Habilitar pasarela instantánea P2P en el Public Hub.`,
  ].join('\n');

  const minutesEn = [
    `# CONFIDENTIAL EXECUTIVE MINUTES — WORDVERSE NEXUS VIP`,
    `Date: ${dateStr} | Room: PREMION VIP Boardroom (E2EE)`,
    `Active Focus: Slide ${curIdx + 1}/4 — ${curSlide.title} (${curSlide.subtitle})`,
    `Audit Hash: 0x9F8E...4C2A (Verified on TRC20 Network)`,
    ``,
    `## 1. VERIFIED PARTICIPANTS`,
    ...participantsEn.map(p => `- ${p}`),
    ``,
    `## 2. BOARD AGREEMENTS AND RESOLUTIONS`,
    `- [APPROVED] Q4 P2P Settlement certified at $48,500,000 USDT (+24.6% vs Q3) with 0% default.`,
    `- [APPROVED] Deployment of 3-of-5 Multi-Sig Vault with distributed custody and 99.98% SLA.`,
    `- [APPROVED] Allocation of 2026 Syndicated Round ($12.5M Liquidity, $5M Reserve, $3.5M AI R&D).`,
    ``,
    `## 3. ACTION ITEMS AND COMMITMENTS`,
    `1. ${localUserInfo.name}: Sign master key #1 for institutional Escrow release.`,
    `2. Andrés Morales: Perform quarterly audit of LatAm validator nodes.`,
    `3. Carlos Mendoza: Enable instant P2P gateway in the Public Hub.`,
  ].join('\n');

  let chosenMd = minutesEs;
  let summarySpeech = `Minuta ejecutiva generada y auditada para ${localUserInfo.name}. Se han registrado 3 acuerdos financieros sobre ${curSlide.title} y 3 compromisos operativos listos para descargar.`;

  if (lang === 'en') {
    chosenMd = minutesEn;
    summarySpeech = `Confidential executive minutes generated in English for ${localUserInfo.name}. 3 financial resolutions on ${curSlide.title} and 3 action items recorded and audited.`;
  } else if (lang === 'dual') {
    chosenMd = [
      `# BILINGUAL EXECUTIVE MINUTES / MINUTA EJECUTIVA BILINGÜE — WORDVERSE NEXUS VIP`,
      `Date / Fecha: ${dateStr} | Room / Sala: PREMION VIP Boardroom (E2EE)`,
      `Slide ${curIdx + 1}/4: ${curSlide.title} | Hash: 0x9F8E...4C2A (TRC20)`,
      ``,
      `============================================================`,
      `🇪🇸 SECCIÓN EN ESPAÑOL`,
      `============================================================`,
      minutesEs,
      ``,
      `============================================================`,
      `🇺🇸 ENGLISH SECTION`,
      `============================================================`,
      minutesEn,
    ].join('\n');
    summarySpeech = `Minuta ejecutiva bilingüe generada en español e inglés para ${localUserInfo.name} con certificación E2EE en red TRC20.`;
  }

  lastGeneratedMinutesText = chosenMd;
  if (aiMinutesContent) {
    aiMinutesContent.textContent = chosenMd;
  }
  if (aiMinutesBox) {
    aiMinutesBox.classList.add('show');
  }
  nexusSay(summarySpeech);
  bridge.send({
    type: 'aiMinutesGenerated',
    slideIndex: curIdx,
    slideTitle: curSlide.title,
    language: lang,
    content: chosenMd,
  });
  return chosenMd;
}

function handleNexusAiAction(action) {
  playHoloClick();
  if (action === 'agenda') {
    if (aiMinutesBox) aiMinutesBox.classList.remove('show');
    nexusSay(`Hola ${localUserInfo.name}. Hoy en el Public Hub tenemos 3 eventos en vivo: 1) Cumbre de Liquidez P2P en el Atrio Central, 2) Auditoría de Contratos Escrow en la recepción, y 3) Networking Ejecutivo VIP en el Mezzanine.`);
  } else if (action === 'elevator') {
    if (aiMinutesBox) aiMinutesBox.classList.remove('show');
    if (playerSitting) standUp();
    player.x = ELEVATOR.x;
    player.z = ELEVATOR.doorZ + 0.08;
    player.y = 0;
    player.rot = Math.PI;
    if (world.elevator && world.elevator.state === 'idle') {
      world.elevator.open();
    }
    nexusSay(`Te he guiado frente al Ascensor Panorámico de Cristal en el ala oeste. Las puertas están abiertas; entra a la cabina o presiona E para subir al Mezzanine.`);
  } else if (action === 'boardroom') {
    goToBoardroom();
    const curIdx = world.getBoardroomSlide ? world.getBoardroomSlide() : 0;
    const curSlide = BOARDROOM_SLIDES[curIdx] || BOARDROOM_SLIDES[0];
    nexusSay(`Bienvenido a The Boardroom VIP, ${localUserInfo.name}. El aislamiento acústico E2EE está activo y la pantalla proyecta: ${curSlide.title}.`);
  } else if (action === 'escrow') {
    if (aiMinutesBox) aiMinutesBox.classList.remove('show');
    nexusSay(`Reporte Escrow en tiempo real: Volumen Q4 en 48.5 millones USDT, 12,480 contratos P2P liquidados en 38.2 segundos promedio y arquitectura Multi-Firma 3 de 5 operativa al 99.98%.`);
  } else if (action === 'mezzanine') {
    if (aiMinutesBox) aiMinutesBox.classList.remove('show');
    nexusSay(`El Nivel 2 Mezzanine cuenta con sofás ejecutivos de cuero, vista panorámica de 360 grados al cilindro holográfico y barra VIP. Puedes subir por el Ascensor Panorámico o por las Escaleras Monumentales.`);
  } else if (action === 'minutes') {
    generateBoardroomMinutes();
  }
}

function answerNexusAiQuery(rawQuery) {
  const q = (rawQuery || '').trim().toLowerCase();
  if (!q) return;
  if (q.includes('ascensor') || q.includes('elevador') || q.includes('subir')) {
    handleNexusAiAction('elevator');
  } else if (q.includes('minuta') || q.includes('resumen') || q.includes('acuerdo') || q.includes('acta')) {
    handleNexusAiAction('minutes');
  } else if (q.includes('privada') || q.includes('boardroom') || q.includes('junta')) {
    handleNexusAiAction('boardroom');
  } else if (q.includes('escrow') || q.includes('p2p') || q.includes('liquidez') || q.includes('usdt')) {
    handleNexusAiAction('escrow');
  } else if (q.includes('mezzanine') || q.includes('piso 2') || q.includes('cafe') || q.includes('café')) {
    handleNexusAiAction('mezzanine');
  } else if (q.includes('evento') || q.includes('agenda') || q.includes('hoy')) {
    handleNexusAiAction('agenda');
  } else {
    nexusSay(`Entendido, ${localUserInfo.name}. Como tu Copiloto Holográfico en WordVerse Nexus, puedo llevarte al Ascensor Panorámico, conectarte a la Sala Privada VIP, auditar las bóvedas Escrow TRC20 o generar la minuta ejecutiva de tu reunión.`);
  }
}

function openNexusAiPanel(initialAction = null) {
  if (!nexusAiPanel) return;
  nexusAiPanel.classList.add('open');
  if (initialAction) {
    handleNexusAiAction(initialAction);
  } else {
    const greeting = `Bienvenido a WordVerse Nexus, ${localUserInfo.name}${localUserInfo.company ? ' (' + localUserInfo.company + ')' : ''}. Soy NEXUS AI, tu conserje ejecutivo holográfico. ¿Deseas consultar los eventos de hoy, ir al Ascensor VIP o generar una minuta de junta?`;
    nexusSay(greeting);
  }
}

function closeNexusAiPanel() {
  if (!nexusAiPanel) return;
  nexusAiPanel.classList.remove('open');
  world.setNexusAiSpeaking?.(false);
}

if (nexusAiBtn) {
  nexusAiBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    if (nexusAiPanel?.classList.contains('open')) closeNexusAiPanel();
    else openNexusAiPanel();
  });
}

if (btnAiMinutes) {
  btnAiMinutes.addEventListener('click', (e) => {
    e.stopPropagation();
    openNexusAiPanel('minutes');
  });
}

if (btnAiClose) {
  btnAiClose.addEventListener('click', (e) => {
    e.stopPropagation();
    closeNexusAiPanel();
  });
}

if (btnAiMute) {
  btnAiMute.addEventListener('click', (e) => {
    e.stopPropagation();
    const muted = setNexusAiVoiceMuted(!isNexusAiVoiceMuted());
    btnAiMute.textContent = muted ? '🔇 Silenciado' : '🔊 Voz IA';
    if (muted) world.setNexusAiSpeaking?.(false);
  });
}

document.querySelectorAll('.ai-quick-btn').forEach((btn) => {
  btn.addEventListener('click', (e) => {
    e.stopPropagation();
    const act = btn.getAttribute('data-ai-action');
    if (act) handleNexusAiAction(act);
  });
});

if (aiQueryForm) {
  aiQueryForm.addEventListener('submit', (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (aiQueryInput && aiQueryInput.value.trim()) {
      answerNexusAiQuery(aiQueryInput.value);
      aiQueryInput.value = '';
    }
  });
}

const btnMinLangEs = document.getElementById('btn-min-lang-es');
const btnMinLangEn = document.getElementById('btn-min-lang-en');
const btnMinLangDual = document.getElementById('btn-min-lang-dual');

if (btnMinLangEs) {
  btnMinLangEs.addEventListener('click', (e) => {
    e.stopPropagation();
    generateBoardroomMinutes('es');
  });
}

if (btnMinLangEn) {
  btnMinLangEn.addEventListener('click', (e) => {
    e.stopPropagation();
    generateBoardroomMinutes('en');
  });
}

if (btnMinLangDual) {
  btnMinLangDual.addEventListener('click', (e) => {
    e.stopPropagation();
    generateBoardroomMinutes('dual');
  });
}

if (btnCopyMinutes) {
  btnCopyMinutes.addEventListener('click', (e) => {
    e.stopPropagation();
    if (!lastGeneratedMinutesText) generateBoardroomMinutes();
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(lastGeneratedMinutesText).catch(() => {});
    }
    flashPrompt('📋 Minuta Ejecutiva copiada al portapapeles');
  });
}

if (btnDownloadMinutes) {
  btnDownloadMinutes.addEventListener('click', (e) => {
    e.stopPropagation();
    if (!lastGeneratedMinutesText) generateBoardroomMinutes();
    try {
      const blob = new Blob([lastGeneratedMinutesText], { type: 'text/markdown;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `Minuta_WordVerse_Nexus_${new Date().toISOString().slice(0, 10)}.md`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      flashPrompt('📥 Minuta Ejecutiva descargada (.MD)');
    } catch (_) {}
  });
}

// =====================================================================
// KIOSCO COMERCIAL INTERACTIVO 3D & RADAR DE AFINIDAD (FASE 5)
// =====================================================================
const KIOSK_PRODUCTS = [
  {
    id: 'prod_node_premion',
    name: '💎 Nodo Validador Institucional PREMION',
    price: '2,500 USDT · Escrow TRC20',
    amountUsdt: 2500,
    desc: 'Licencia anual de nodo validador con participación directa en el pool de liquidez P2P de WordVerse y rendimiento estimado del 18.4% APY.',
    meta: 'Sponsor Verificado: Andes Capital · Custodia Multi-Firma 3/5',
    vendor: 'Andrés Morales (Andes Capital)',
  },
  {
    id: 'prod_vault_e2ee',
    name: '🛡️ Bóveda Hardware Multi-Firma E2EE',
    price: '850 USDT · Escrow TRC20',
    amountUsdt: 850,
    desc: 'Dispositivo biométrico de grado bancario con firma distribuida 3-de-5 para liberación de contratos Escrow institucionales.',
    meta: 'Sponsor Verificado: Pacific Escrow · Envío Asegurado Global',
    vendor: 'Sofía Herrera (Pacific Escrow)',
  },
  {
    id: 'prod_suite_vip',
    name: '🏛️ Suite Corporativa VIP Dedicada (Anual)',
    price: '4,200 USDT · Escrow TRC20',
    amountUsdt: 4200,
    desc: 'Sala de juntas privada 24/7 con aislamiento acústico E2EE, pantalla 16:9 personalizada y conserje holográfico Nexus AI exclusivo.',
    meta: 'Sponsor Verificado: Nova Pay · Activación Instantánea',
    vendor: 'Carlos Mendoza (Nova Pay)',
  },
];

let selectedKioskIdx = 0;
let currentRadarTarget = null;

function renderKioskQr(p) {
  if (!kioskQrCanvas || !p) return;
  const ctx = kioskQrCanvas.getContext('2d');
  const w = kioskQrCanvas.width;
  const h = kioskQrCanvas.height;
  ctx.fillStyle = '#050b18';
  ctx.fillRect(0, 0, w, h);

  const grid = 21;
  const cell = w / grid;
  const seed = (p.id || 'prod').split('').reduce((acc, c) => acc + c.charCodeAt(0), 19);

  function isPos(r, c) {
    return (r < 7 && c < 7) || (r < 7 && c >= grid - 7) || (r >= grid - 7 && c < 7);
  }

  function drawFinder(pr, pc) {
    ctx.fillStyle = '#d4af37';
    ctx.fillRect(pc * cell, pr * cell, 7 * cell, 7 * cell);
    ctx.fillStyle = '#050b18';
    ctx.fillRect((pc + 1) * cell, (pr + 1) * cell, 5 * cell, 5 * cell);
    ctx.fillStyle = '#00f0ff';
    ctx.fillRect((pc + 2) * cell, (pr + 2) * cell, 3 * cell, 3 * cell);
  }
  drawFinder(0, 0);
  drawFinder(0, grid - 7);
  drawFinder(grid - 7, 0);

  ctx.fillStyle = '#00ff87';
  for (let r = 0; r < grid; r++) {
    for (let c = 0; c < grid; c++) {
      if (isPos(r, c)) continue;
      const v = (Math.sin(r * 12.9898 + c * 78.233 + seed) * 43758.5453) % 1;
      if (v > 0.44) {
        ctx.fillRect(c * cell + 0.6, r * cell + 0.6, cell - 1.2, cell - 1.2);
      }
    }
  }

  if (kioskTrc20Addr) {
    kioskTrc20Addr.textContent = `TK7gWordverse${p.id.replace('prod_', '').slice(0, 6)}Vault9x1`;
  }
}

function selectKioskProduct(idx) {
  playHoloClick();
  selectedKioskIdx = ((idx % KIOSK_PRODUCTS.length) + KIOSK_PRODUCTS.length) % KIOSK_PRODUCTS.length;
  world.setKioskProduct?.(selectedKioskIdx);
  const p = KIOSK_PRODUCTS[selectedKioskIdx];
  if (kioskProdName) kioskProdName.textContent = p.name;
  if (kioskProdPrice) kioskProdPrice.textContent = p.price;
  if (kioskProdDesc) kioskProdDesc.textContent = p.desc;
  if (kioskProdMeta) kioskProdMeta.textContent = p.meta;
  if (kioskReceiptBox) kioskReceiptBox.classList.remove('show');
  renderKioskQr(p);
  document.querySelectorAll('.kiosk-tab-btn').forEach((b) => {
    b.classList.toggle('active', Number(b.getAttribute('data-kiosk-idx')) === selectedKioskIdx);
  });
}

function openKioskPanel(prodIdx = null) {
  if (!kioskPanel) return;
  kioskPanel.classList.add('open');
  if (typeof prodIdx === 'number') selectKioskProduct(prodIdx);
  else selectKioskProduct(selectedKioskIdx);
}

function closeKioskPanel() {
  if (!kioskPanel) return;
  kioskPanel.classList.remove('open');
  if (kioskQrBox) kioskQrBox.style.display = 'none';
}

function buyKioskProductEscrow() {
  playAiWakeChime();
  const p = KIOSK_PRODUCTS[selectedKioskIdx];
  const escrowId = `#ESC-${48210 + selectedKioskIdx * 137}`;
  if (kioskReceiptBox) {
    kioskReceiptBox.innerHTML = `✅ <strong>CONTRATO ESCROW ${escrowId} ACTIVADO</strong><br/>Activo: ${p.name}<br/>Monto bloqueado en Bóveda 3/5: <strong>${p.price}</strong><br/>Vendedor notificado: ${p.vendor}`;
    kioskReceiptBox.classList.add('show');
  }
  if (player.avatar) {
    player.avatar.showEmote('💎', performance.now() / 1000);
    player.avatar.playGesture?.('clap');
  }
  localWalletBalance = Math.max(0, localWalletBalance - (p.amountUsdt || 100));
  updateWalletDisplay(localWalletBalance);
  showHoloToast({
    title: 'Contrato Escrow Creado',
    message: `${p.name} · ${p.price} en custodia multi-firma 3/5`,
    icon: '🛡️',
  });
  flashPrompt(`⚡ Escrow ${escrowId} creado: ${p.name} (${p.price})`);
  bridge.send({
    type: 'kioskEscrowPurchase',
    escrowId,
    productId: p.id,
    productName: p.name,
    amountUsdt: p.amountUsdt,
    vendor: p.vendor,
  });
}

function contactKioskVendor() {
  playHoloClick();
  const p = KIOSK_PRODUCTS[selectedKioskIdx];
  if (kioskReceiptBox) {
    kioskReceiptBox.innerHTML = `💬 <strong>CANAL DIRECTO ABIERTO CON VENDEDOR VIP</strong><br/>Ejecutivo: <strong>${p.vendor}</strong><br/>Estado: En línea en WordVerse Hub · Respuesta inmediata habilitada.`;
    kioskReceiptBox.classList.add('show');
  }
  if (player.avatar) {
    player.avatar.showEmote('🤝', performance.now() / 1000);
    player.avatar.playGesture?.('handshake');
  }
  flashPrompt(`🤝 Conectado con ${p.vendor}`);
}

if (kioskBtn) {
  kioskBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    if (kioskPanel?.classList.contains('open')) closeKioskPanel();
    else openKioskPanel();
  });
}

if (btnKioskClose) {
  btnKioskClose.addEventListener('click', (e) => {
    e.stopPropagation();
    closeKioskPanel();
  });
}

document.querySelectorAll('.kiosk-tab-btn').forEach((btn) => {
  btn.addEventListener('click', (e) => {
    e.stopPropagation();
    selectKioskProduct(Number(btn.getAttribute('data-kiosk-idx') || 0));
  });
});

if (btnKioskBuy) {
  btnKioskBuy.addEventListener('click', (e) => {
    e.stopPropagation();
    buyKioskProductEscrow();
  });
}

if (btnKioskVendor) {
  btnKioskVendor.addEventListener('click', (e) => {
    e.stopPropagation();
    contactKioskVendor();
  });
}

if (btnKioskQr) {
  btnKioskQr.addEventListener('click', (e) => {
    e.stopPropagation();
    playHoloClick();
    if (kioskQrBox) {
      const isVisible = kioskQrBox.style.display !== 'none';
      kioskQrBox.style.display = isVisible ? 'none' : 'flex';
      if (!isVisible) renderKioskQr(KIOSK_PRODUCTS[selectedKioskIdx]);
    }
  });
}

if (btnCloseQrBox) {
  btnCloseQrBox.addEventListener('click', (e) => {
    e.stopPropagation();
    if (kioskQrBox) kioskQrBox.style.display = 'none';
  });
}

if (btnCopyTrc20) {
  btnCopyTrc20.addEventListener('click', (e) => {
    e.stopPropagation();
    playHoloClick();
    const p = KIOSK_PRODUCTS[selectedKioskIdx];
    const uri = `tron:${kioskTrc20Addr?.textContent || 'TK7gWordverseVault9x1'}?amount=${p.amountUsdt}&token=USDT`;
    if (navigator.clipboard) navigator.clipboard.writeText(uri).catch(() => {});
    showHoloToast({
      title: 'URI TRC20 Copiado',
      message: uri,
      icon: '📋',
    });
  });
}

if (btnKioskQrConfirm) {
  btnKioskQrConfirm.addEventListener('click', (e) => {
    e.stopPropagation();
    if (kioskQrBox) kioskQrBox.style.display = 'none';
    buyKioskProductEscrow();
    showHoloToast({
      title: 'Pago QR TRC20 Verificado',
      message: 'Liquidación confirmada en bloque Tron · Escrow activo',
      icon: '✅',
    });
  });
}

if (hudWalletPill) {
  hudWalletPill.addEventListener('click', (e) => {
    e.stopPropagation();
    playHoloClick();
    bridge.send({ type: 'interact', kind: 'escrow' });
    showHoloToast({
      title: 'Billetera USDT TRC20',
      message: `Balance disponible: ${Math.round(localWalletBalance).toLocaleString()} USDT`,
      icon: '💰',
    });
  });
}

if (btnRadarConnect) {
  btnRadarConnect.addEventListener('click', (e) => {
    e.stopPropagation();
    playHoloClick();
    if (currentRadarTarget) {
      if (player.avatar) {
        player.avatar.showEmote('🤝', performance.now() / 1000);
        player.avatar.playGesture?.('handshake');
      }
      currentRadarTarget.avatar?.showEmote?.('🤝', performance.now() / 1000);
      flashPrompt(`📡 Match ${currentRadarTarget.affinity}%: Solicitud VIP enviada a ${currentRadarTarget.name} (${currentRadarTarget.specialty})`);
      bridge.send({
        type: 'affinityConnected',
        id: currentRadarTarget.id,
        name: currentRadarTarget.name,
        affinity: currentRadarTarget.affinity,
        specialty: currentRadarTarget.specialty,
      });
    }
  });
}

function openHoloCard(avatar) {
  if (!holoCardPanel || !avatar) return;
  currentHoloAvatar = avatar;
  playHoloClick();

  const isSelf = avatar.isLocal || avatar.id === 'local' || avatar.id === player.avatar?.id;
  if (holoCardBadge) holoCardBadge.textContent = isSelf ? '⭐' : '👔';
  if (holoCardName) holoCardName.innerHTML = `${avatar.name || 'Ejecutivo'} <span style="font-size:12px">🛡️</span>`;
  if (holoCardTitle) holoCardTitle.textContent = `${avatar.company || 'WordVerse Corporate Partner'} · Ejecutivo VIP`;
  if (holoCardStatus) holoCardStatus.textContent = isSelf ? 'Sesión Local Activa (Tú)' : 'En línea en The Hub';

  const userSeed = Math.abs((avatar.id || '').split('').reduce((acc, c) => acc + c.charCodeAt(0), 0));
  const trades = 30 + (userSeed % 65);
  if (holoMetricRep) holoMetricRep.textContent = `⭐ 99.${8 + (userSeed % 2)}% (${trades} trades)`;
  if (holoMetricWallet) holoMetricWallet.textContent = `TK7g...${(avatar.id || '9A').slice(-2)}x${userSeed % 9}`;
  if (holoMetricLang) holoMetricLang.textContent = '🌐 ES · EN · PT (IA Live)';

  holoCardPanel.classList.add('open');
}

function closeHoloCard() {
  if (holoCardPanel) holoCardPanel.classList.remove('open');
  currentHoloAvatar = null;
}

if (btnHoloClose) {
  btnHoloClose.addEventListener('click', (e) => {
    e.stopPropagation();
    closeHoloCard();
  });
}

if (btnHoloChat) {
  btnHoloChat.addEventListener('click', (e) => {
    e.stopPropagation();
    playHoloClick();
    if (currentHoloAvatar) {
      bridge.send({ type: 'interact', kind: 'networking', targetUserId: currentHoloAvatar.id });
      flashPrompt(`💬 Abriendo canal de chat directo con ${currentHoloAvatar.name}`);
    }
    closeHoloCard();
  });
}

if (btnHoloWave) {
  btnHoloWave.addEventListener('click', (e) => {
    e.stopPropagation();
    playHoloClick();
    if (player.avatar?.playGesture) {
      player.avatar.playGesture('wave');
      player.avatar.showEmote?.('👋', performance.now() / 1000);
    }
    if (currentHoloAvatar && currentHoloAvatar !== player.avatar && currentHoloAvatar.playGesture) {
      currentHoloAvatar.playGesture('wave');
      currentHoloAvatar.showEmote?.('🤝', performance.now() / 1000);
    }
    flashPrompt('🤝 Saludo ejecutivo transmitido');
    closeHoloCard();
  });
}

if (btnHoloEscrow) {
  btnHoloEscrow.addEventListener('click', (e) => {
    e.stopPropagation();
    playHoloClick();
    if (currentHoloAvatar) {
      bridge.send({ type: 'interact', kind: 'escrow', targetUserId: currentHoloAvatar.id });
      flashPrompt(`💼 Iniciando contrato Escrow B2B con ${currentHoloAvatar.name}`);
    }
    closeHoloCard();
  });
}

const TELEPORT_ZONES = {
  atrium: { name: 'Atrio Central', x: 0.0, z: 0.32, y: 0, rot: 0, camYaw: 0, isBoardroom: false, icon: '🏛️' },
  shest: { name: 'Shest Coffee Bar', x: -0.45, z: 0.30, y: 0, rot: Math.PI * 0.25, camYaw: 0.5, isBoardroom: false, icon: '☕' },
  mezzanine: { name: 'Mezzanine VIP Lounge', x: 0.55, z: -0.58, y: MEZZANINE_Y, rot: Math.PI, camYaw: Math.PI, isBoardroom: false, icon: '🛋️' },
  boardroom: { name: 'The Boardroom VIP', isBoardroom: true, icon: '💼' },
  elevator: { name: 'Ascensor Panorámico', x: -0.62, z: 0.16, y: 0, rot: 0, camYaw: 0, isBoardroom: false, icon: '🏢' },
};

function openTeleportPanel() {
  if (!teleportPanel) return;
  closeNexusAiPanel();
  closeKioskPanel();
  closeHoloCard();
  teleportPanel.classList.add('open');
  playHoloClick();
}

function closeTeleportPanel() {
  if (!teleportPanel) return;
  teleportPanel.classList.remove('open');
}

function teleportTo(zoneKey) {
  const zone = TELEPORT_ZONES[zoneKey];
  if (!zone) return;
  closeTeleportPanel();

  if (teleportOverlay) {
    teleportOverlay.classList.add('active');
  }
  playAiWakeChime();

  setTimeout(() => {
    if (playerSitting) standUp();

    if (zone.isBoardroom) {
      if (player.x <= 1.8) {
        goToBoardroom({ viaPortal: false, notifyFlutter: true });
      }
    } else {
      if (player.x > 1.8) {
        exitBoardroomToEntryPoint({ notifyFlutter: true });
      }
      player.x = zone.x;
      player.z = zone.z;
      player.y = zone.y || 0;
      player.rot = zone.rot || 0;
      player.vy = 0;
      player.onGround = true;

      cam.yaw = zone.camYaw ?? 0;
      cam.pitch = 0.28;
      cam.pos.set(player.x * S, player.y + 2.0, player.z * S + 3.8);

      bridge.send({ type: 'moved', x: player.x, z: player.z, rot: player.rot, moving: false });
    }

    showHoloToast({
      title: 'Teletransportación Cuántica',
      message: `Has llegado a ${zone.name}`,
      icon: zone.icon,
      duration: 3800,
    });

    setTimeout(() => {
      if (teleportOverlay) teleportOverlay.classList.remove('active');
    }, 180);
  }, 120);
}

if (btnFastTravel) {
  btnFastTravel.addEventListener('click', (e) => {
    e.stopPropagation();
    if (teleportPanel?.classList.contains('open')) closeTeleportPanel();
    else openTeleportPanel();
  });
}

if (btnTeleportClose) {
  btnTeleportClose.addEventListener('click', (e) => {
    e.stopPropagation();
    closeTeleportPanel();
  });
}

document.querySelectorAll('.teleport-dest-btn').forEach((btn) => {
  btn.addEventListener('click', (e) => {
    e.stopPropagation();
    const zoneKey = btn.getAttribute('data-zone');
    if (zoneKey) teleportTo(zoneKey);
  });
});

window.addEventListener('keydown', (e) => {
  if (document.activeElement === aiQueryInput) return;
  if (e.repeat) return;
  const k = e.key.toLowerCase();
  if (k === 'e' || k === 'enter') {
    e.preventDefault();
    interact();
    return;
  }
  keys.add(k);
  if (k === 'v' || k === 'c') cycleCameraMode();
  if (k === 'escape') {
    closeNexusAiPanel();
    closeKioskPanel();
    closeHoloCard();
    closeTeleportPanel();
  }
  if (k === 't') {
    if (teleportPanel?.classList.contains('open')) closeTeleportPanel();
    else openTeleportPanel();
  }
  if (k === 'p') {
    if (holoCardPanel?.classList.contains('open')) closeHoloCard();
    else if (player.avatar) openHoloCard(player.avatar);
  }
  if (k === 'n') {
    if (nexusAiPanel?.classList.contains('open')) closeNexusAiPanel();
    else openNexusAiPanel();
  }
  if (k === 'k') {
    if (kioskPanel?.classList.contains('open')) closeKioskPanel();
    else openKioskPanel();
  }
  if (isInBoardroom(player.x, player.z)) {
    if (k === '[' || k === 'pageup') {
      changeBoardroomSlide('prev');
      e.preventDefault();
    } else if (k === ']' || k === 'pagedown') {
      changeBoardroomSlide('next');
      e.preventDefault();
    }
  }
  if (['arrowup', 'arrowdown', 'arrowleft', 'arrowright', ' '].includes(k)) e.preventDefault();
});
window.addEventListener('keyup', (e) => keys.delete(e.key.toLowerCase()));
window.addEventListener('blur', () => keys.clear());

let drag = null;
canvas.addEventListener('pointerdown', (e) => {
  try { canvas.setPointerCapture(e.pointerId); } catch (_) {}
  drag = { id: e.pointerId, x: e.clientX, y: e.clientY, moved: 0 };
  window.focus();
});
window.addEventListener('pointermove', (e) => {
  if (!drag) return;
  const dx = e.clientX - drag.x;
  const dy = e.clientY - drag.y;
  drag.x = e.clientX;
  drag.y = e.clientY;
  drag.moved += Math.abs(dx) + Math.abs(dy);
  cam.yaw -= dx * 0.0055;
  cam.pitch = THREE.MathUtils.clamp(cam.pitch + dy * 0.004, 0.04, 1.15);
});
window.addEventListener('pointerup', (e) => {
  if (drag && drag.moved < 6) pick(e);
  drag = null;
});
window.addEventListener('pointercancel', () => { drag = null; });

// Soporte táctil directo para móviles
canvas.addEventListener('touchstart', (e) => {
  if (e.touches.length === 1) {
    const t = e.touches[0];
    drag = { id: 99999, x: t.clientX, y: t.clientY, moved: 0 };
  }
}, { passive: true });
window.addEventListener('touchmove', (e) => {
  if (!drag || e.touches.length !== 1) return;
  const t = e.touches[0];
  const dx = t.clientX - drag.x;
  const dy = t.clientY - drag.y;
  drag.x = t.clientX;
  drag.y = t.clientY;
  drag.moved += Math.abs(dx) + Math.abs(dy);
  cam.yaw -= dx * 0.0055;
  cam.pitch = THREE.MathUtils.clamp(cam.pitch + dy * 0.004, 0.04, 1.15);
}, { passive: true });
window.addEventListener('touchend', () => { drag = null; }, { passive: true });
canvas.addEventListener('wheel', (e) => {
  e.preventDefault();
  cam.zoom = THREE.MathUtils.clamp(cam.zoom + Math.sign(e.deltaY) * 0.08, 0.5, 1.8);
}, { passive: false });

const ray = new THREE.Raycaster();
function pick(e) {
  const ndc = new THREE.Vector2((e.clientX / window.innerWidth) * 2 - 1, -(e.clientY / window.innerHeight) * 2 + 1);
  ray.setFromCamera(ndc, camera);
  const avatarTargets = [];
  if (player.avatar) avatarTargets.push(...player.avatar.hitTargets);
  for (const r of remotes.values()) avatarTargets.push(...r.avatar.hitTargets);
  const hit = ray.intersectObjects([...avatarTargets, ...world.interactables], false)[0];
  if (!hit) return;
  if (hit.object.userData.isNexusAi) {
    openNexusAiPanel();
    return;
  }
  if (hit.object.userData.isKiosk) {
    openKioskPanel();
    return;
  }
  if (hit.object.userData.isSlideButton) {
    changeBoardroomSlide(hit.object.userData.slideAction === 'next' ? 'next' : 'prev');
    return;
  }
  if (hit.object.userData.seatId) {
    const clickedSeat = SEATS.find(s => s.id === hit.object.userData.seatId);
    if (clickedSeat) {
      sitOnSeat(clickedSeat);
      return;
    }
  }
  if (hit.object.userData.isPrivatePortal) {
    goToBoardroom({ viaPortal: true, notifyFlutter: true });
    return;
  }
  if (hit.object.userData.isBoardroomExit) {
    exitBoardroomToEntryPoint({ notifyFlutter: true });
    return;
  }
  if (hit.object.userData.hotspot) {
    const h = hit.object.userData.hotspot;
    // Hay que estar cerca para interactuar; si no, solo se resalta el aviso
    if (near?.kind === h.kind) bridge.send({ type: 'interact', kind: h.kind });
    else flashPrompt(`Acércate a «${h.title}» para interactuar`);
    return;
  }
  let o = hit.object;
  while (o && !o.userData.avatar) o = o.parent;
  if (o) {
    if (o.userData.avatar.id === 'npc_receptionist') {
      openNexusAiPanel();
      return;
    }
    openHoloCard(o.userData.avatar);
    bridge.send({ type: 'avatarTapped', id: o.userData.avatar.id, isLocal: o.userData.avatar.isLocal });
    return;
  }
}

let playerSitting = false;
let currentSeat = null;
let sitGraceTimer = 0;
let portalCooldown = 0;
let lastLobbyEntryPose = {
  x: 0.62,
  z: -0.56,
  y: 0,
  rot: 0,
  camYaw: 0,
};

function sitOnSeat(seat) {
  currentSeat = seat;
  playerSitting = true;
  sitGraceTimer = 0.45;
  keys.clear();
  joy = { x: 0, y: 0 };
  player.x = seat.x;
  player.z = seat.z;
  player.y = seat.y ?? 0;
  player.rot = seat.rot;
  player.moving = 0;
  cam.yaw = seat.rot;
  cam.pitch = 0.20;
  cam.zoom = 0.85;
  if (player.avatar) {
    player.avatar.setSitting(true);
    player.avatar.group.position.set(player.x * S, player.y, player.z * S);
    player.avatar.group.rotation.y = player.rot;
  }
  promptEl.textContent = `🪑 Sentado en «${seat.name}» · [E / WASD] Levantarse`;
  promptEl.classList.add('show');
  bridge.send({ type: 'moved', x: player.x, z: player.z, rot: player.rot, moving: false });
}

function standUp() {
  if (!playerSitting) return;
  const seatRef = currentSeat;
  playerSitting = false;
  currentSeat = null;
  sitGraceTimer = 0;
  cam.zoom = 1.0;
  if (seatRef) {
    const stepDir = seatRef.id.startsWith('board_seat') ? seatRef.rot + Math.PI : seatRef.rot;
    const rawX = seatRef.x + Math.sin(stepDir) * 0.045;
    const rawZ = seatRef.z + Math.cos(stepDir) * 0.045;
    const resolved = resolve(rawX, rawZ, player.y);
    player.x = resolved.x;
    player.z = resolved.z;
  }
  if (player.avatar) {
    player.avatar.setSitting(false);
    player.avatar.group.position.set(player.x * S, player.y, player.z * S);
  }
  promptEl.textContent = 'De pie';
  promptEl.classList.remove('show');
  bridge.send({ type: 'moved', x: player.x, z: player.z, rot: player.rot, moving: false });
}

function goToBoardroom(opts = {}) {
  const viaPortal = opts?.viaPortal === true;
  const notifyFlutter = opts?.notifyFlutter !== false;

  if (playerSitting) standUp();

  // Guardar exactamente el punto del Lobby/Mezzanine por donde entró el jugador
  if (player.x <= 1.8) {
    if (viaPortal || isNearPrivatePortal(player.x, player.z)) {
      lastLobbyEntryPose = {
        x: 0.62,
        z: -0.56,
        y: 0,
        rot: 0,
        camYaw: 0,
      };
    } else {
      lastLobbyEntryPose = {
        x: player.x,
        z: player.z,
        y: player.y || 0,
        rot: player.rot || 0,
        camYaw: cam.yaw || 0,
      };
    }
  }

  portalCooldown = 2.0;
  player.x = 2.60;
  player.z = 0.42;
  player.y = 0;
  player.rot = Math.PI;
  cam.yaw = 0;
  cam.pitch = 0.26;
  cam.pos.set(player.x * S, player.y + 2.3, player.z * S + 3.8);
  btnRoomPrivate?.classList.add('active');
  btnRoomPublic?.classList.remove('active');
  flashPrompt('🔒 Conectado a Sala Privada VIP WordVerse');
  playCameraSwitch();
  if (notifyFlutter) {
    bridge.send({ type: 'subRoomChanged', name: 'Sala Privada' });
    bridge.send({ type: 'moved', x: player.x, z: player.z, rot: player.rot, moving: false });
  }
}

function exitBoardroomToEntryPoint(opts = {}) {
  const notifyFlutter = opts?.notifyFlutter !== false;
  if (playerSitting) standUp();

  portalCooldown = 2.4;
  // Regresar exactamente al punto por donde el jugador entró a la Sala Privada
  const targetPose = lastLobbyEntryPose && lastLobbyEntryPose.x <= 1.8
    ? lastLobbyEntryPose
    : { x: 0.62, z: -0.56, y: 0, rot: 0, camYaw: 0 };

  player.x = targetPose.x;
  player.z = targetPose.z;
  player.y = targetPose.y || 0;
  player.rot = targetPose.rot ?? 0;
  cam.yaw = targetPose.camYaw ?? 0;
  cam.pitch = 0.28;
  cam.pos.set(player.x * S, player.y + 2.0, player.z * S + 3.8);

  btnRoomPublic?.classList.add('active');
  btnRoomPrivate?.classList.remove('active');
  flashPrompt('🏛️ De regreso en la Sala Pública (Punto de Entrada)');
  playCameraSwitch();
  if (notifyFlutter) {
    bridge.send({ type: 'subRoomChanged', name: 'Sala Principal' });
    bridge.send({ type: 'moved', x: player.x, z: player.z, rot: player.rot, moving: false });
  }
}

function goToPublicHub() {
  if (player.x > 1.8) {
    exitBoardroomToEntryPoint({ notifyFlutter: true });
    return;
  }
  if (playerSitting) standUp();
  portalCooldown = 1.5;
  player.x = SPAWN.x;
  player.z = SPAWN.z;
  player.y = 0;
  player.rot = 0;
  cam.yaw = 0;
  cam.pos.set(player.x * S, player.y + 1.8, player.z * S + 4.2);
  btnRoomPublic?.classList.add('active');
  btnRoomPrivate?.classList.remove('active');
  flashPrompt('¡Bienvenido a la Plaza Pública (The Hub)!');
  playCameraSwitch();
}

btnRoomPublic?.addEventListener('click', () => goToPublicHub());
btnRoomPrivate?.addEventListener('click', () => goToBoardroom({ viaPortal: false, notifyFlutter: true }));

function interact() {
  if (playerSitting) {
    standUp();
    return;
  }
  const nearSeat = SEATS.find(s => Math.hypot(player.x - s.x, player.z - s.z) < 0.24 && Math.abs(player.y - s.y) < 1.0);
  if (nearSeat) {
    sitOnSeat(nearSeat);
    return;
  }
  if (nearElevator && world.elevator) {
    if (world.elevator.state === 'idle') {
      const nextFloor = world.elevator.floor === 1 ? 2 : 1;
      world.elevator.startTrip(nextFloor);
      flashPrompt(`Viajando hacia ${nextFloor === 2 ? 'Piso 2 (Mezzanine)' : 'Piso 1 (Atrio)'}...`);
    }
    return;
  }
  if (isNearPrivatePortal(player.x, player.z)) {
    goToBoardroom({ viaPortal: true, notifyFlutter: true });
    return;
  }
  if (isNearBoardroomExit(player.x, player.z)) {
    exitBoardroomToEntryPoint({ notifyFlutter: true });
    return;
  }
  if (isNearReceptionDesk(player.x, player.z, player.y)) {
    openNexusAiPanel();
    return;
  }
  if (isNearKiosk(player.x, player.z, player.y)) {
    openKioskPanel();
    return;
  }
  if (near) bridge.send({ type: 'interact', kind: near.kind });
}

promptEl.style.cursor = 'pointer';
promptEl.addEventListener('click', interact);

if (actionBtn) {
  actionBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    interact();
  });
}

let promptTimer = 0;
function flashPrompt(text) {
  promptEl.textContent = text;
  promptEl.classList.add('show');
  promptTimer = 1.8;
}

// ------------------------------------------------------------------ main loop
const clock = new THREE.Clock();
let fpsAcc = 0;
let fpsFrames = 0;
let lowFpsSeconds = 0;

function frame() {
  requestAnimationFrame(frame);
  const dt = Math.min(clock.getDelta(), 0.1);
  const t = clock.elapsedTime;

  if (portalCooldown > 0) portalCooldown = Math.max(0, portalCooldown - dt);
  if (sitGraceTimer > 0) sitGraceTimer = Math.max(0, sitGraceTimer - dt);

  if (player.avatar) {
    // Entrada: teclado + joystick de Flutter
    let fwd = 0;
    let strafe = 0;
    if (keys.has('w') || keys.has('arrowup')) fwd += 1;
    if (keys.has('s') || keys.has('arrowdown')) fwd -= 1;
    if (keys.has('d') || keys.has('arrowright')) strafe += 1;
    if (keys.has('a') || keys.has('arrowleft')) strafe -= 1;
    fwd += -joy.y;
    strafe += joy.x;

    if (playerSitting) {
      if (sitGraceTimer <= 0 && (Math.abs(fwd) > 0.15 || Math.abs(strafe) > 0.15 || keys.has(' '))) {
        standUp();
      }
      fwd = 0;
      strafe = 0;
    }

    const move = cameraRelativeMove(cam.yaw + cam.dartYaw, THREE.MathUtils.clamp(fwd, -1, 1), THREE.MathUtils.clamp(strafe, -1, 1));
    const running = keys.has('shift');
    const speed = (running ? RUN : WALK) * move.len;
    const isMoving = move.len > 0.05;
    // 1. Detección precisa de ascensor y escaleras
    const isInsideElev = world.elevator && world.elevator.isInside(player.x * S, player.z * S);
    const isNearElev = world.elevator && world.elevator.isNear(player.x * S, player.z * S, player.y);
    nearElevator = isNearElev || isInsideElev;

    // Si el jugador está fuera de la cabina, registrar que ya salió
    if (!isInsideElev && world.elevator) {
      world.elevator.hasExitedCab = true;
    }

    // Si el jugador entra a la cabina del ascensor:
    if (isInsideElev && world.elevator) {
      elevatorPlayerInside = true;
      player.y = world.elevator.y;
    } else {
      if (world.elevator && world.elevator.state === 'idle') {
        elevatorPlayerInside = false;
      }
      if (isInStairs(player.x, player.z)) {
        player.y = getStairHeight(player.z);
      } else if (player.y >= 3.0) {
        player.y = MEZZANINE_Y;
      } else if (!elevatorPlayerInside) {
        player.y = 0;
      }
    }

    // Mientras el ascensor está en tránsito (cerrando o subiendo/bajando)
    let moveBlocked = false;
    if (world.elevator && (world.elevator.state === 'moving' || world.elevator.state === 'closing') && elevatorPlayerInside) {
      player.y = world.elevator.y;
      player.x = ELEVATOR.x;
      player.z = ELEVATOR.z;
      moveBlocked = true;
      const targetFloorName = world.elevator.targetFloor === 2 ? 'Piso 2 (Mezzanine)' : 'Piso 1 (Atrio)';
      promptEl.textContent = `Ascensor en tránsito · ${targetFloorName}`;
      promptEl.classList.add('show');
    }

    if (isMoving && !moveBlocked) {
      const next = resolve(player.x + move.dx * speed * dt, player.z + move.dz * speed * dt, player.y);
      player.x = next.x;
      player.z = next.z;
      const target = Math.atan2(move.dx, move.dz);
      let d = target - player.rot;
      d = Math.atan2(Math.sin(d), Math.cos(d));
      player.rot += d * Math.min(1, dt * 12);

      // Detección de portales interactivos entre el Lobby y The Boardroom (Sala Privada)
      if (portalCooldown <= 0) {
        if (isNearPrivatePortal(player.x, player.z)) {
          goToBoardroom({ viaPortal: true, notifyFlutter: true });
        } else if (isNearBoardroomExit(player.x, player.z)) {
          exitBoardroomToEntryPoint({ notifyFlutter: true });
        }
      }

      // Sintetizador reactivo de pisadas espaciales según la superficie
      footstepTimer -= dt;
      if (footstepTimer <= 0) {
        footstepTimer = running ? 0.32 : 0.44;
        let surface = 'marble';
        if (isInStairs(player.x, player.z)) {
          surface = 'stairs';
        } else if (player.y >= 3.0 && Math.abs(player.z - (-0.82 + 0.22)) < 0.12) {
          surface = 'carpet';
        }
        playFootstep(surface);
        startAtmosphere();
      }
    } else {
      footstepTimer = 0;
    }

    player.moving = isMoving ? (running ? 1.35 : 1) * move.len : 0;
    player.avatar.group.position.set(player.x * S, player.y, player.z * S);
    player.avatar.group.rotation.y = player.rot;
    player.avatar.update(dt, t, player.moving);

    // Abrir puertas automáticamente al aproximarse al piso correspondiente
    if (isNearElev && world.elevator && world.elevator.state === 'idle' && !isInsideElev) {
      world.elevator.open();
    }

    // Hotspot cercano
    const nh = nearestHotspot(player.x, player.z, hotspots);
    if (nh?.kind !== near?.kind) {
      near = nh;
      world.setNearHotspot(nh?.kind);
    }

    // Actualizar aislamiento acústico y audio espacial en tiempo real
    updateSpatialAudio(player.x, player.z, isInBoardroom(player.x, player.z));

    const nearSeat = !playerSitting ? SEATS.find(s => Math.hypot(player.x - s.x, player.z - s.z) < 0.22 && Math.abs(player.y - s.y) < 1.0) : null;
    const isNearPriv = isNearPrivatePortal(player.x, player.z);
    const isNearPrivExit = isNearBoardroomExit(player.x, player.z);
    const isNearRec = isNearReceptionDesk(player.x, player.z, player.y);
    const isNearKioskStand = isNearKiosk(player.x, player.z, player.y);

    if (playerSitting) {
      promptEl.textContent = `🪑 Sentado en «${currentSeat?.name || 'Sillón'}» · [E] Levantarse`;
      promptEl.classList.add('show');
    } else if (nearSeat) {
      promptEl.textContent = `🪑 [E] Sentarse en «${nearSeat.name}»`;
      promptEl.classList.add('show');
    } else if (isInsideElev && world.elevator) {
      if (world.elevator.state === 'idle') {
        const nextFloorName = world.elevator.floor === 1 ? 'Piso 2 (Mezzanine)' : 'Piso 1 (Atrio)';
        promptEl.textContent = `🛗 [E] Viajar a ${nextFloorName}`;
        promptEl.classList.add('show');
      }
    } else if (nearElevator && world.elevator) {
      if (world.elevator.state === 'idle') {
        const targetFloorName = world.elevator.floor === 1 ? 'Piso 2 (Mezzanine)' : 'Piso 1 (Atrio)';
        promptEl.textContent = `🛗 [E] Tomar Ascensor (${targetFloorName})`;
        promptEl.classList.add('show');
      }
    } else if (isNearPriv) {
      promptEl.textContent = `🔒 [E] Entrar a Sala Privada VIP`;
      promptEl.classList.add('show');
    } else if (isNearPrivExit) {
      promptEl.textContent = `🏛️ [E] Volver a Sala Pública`;
      promptEl.classList.add('show');
    } else if (isNearRec) {
      promptEl.textContent = `🤖 [E] Hablar con NEXUS AI`;
      promptEl.classList.add('show');
    } else if (isNearKioskStand) {
      promptEl.textContent = `🛍️ [E] Abrir Kiosco P2P`;
      promptEl.classList.add('show');
    } else if (isInStairs(player.x, player.z)) {
      const dirText = player.y > 2.0 ? 'Bajando al Atrio' : 'Subiendo al Mezzanine';
      promptEl.textContent = `⬆ Escalera Imperial · ${dirText}`;
      promptEl.classList.add('show');
    } else if (nh) {
      promptEl.textContent = `✦ [E] Interactuar: ${nh.title}`;
      promptEl.classList.add('show');
    } else {
      if (promptTimer <= 0) promptEl.classList.remove('show');
    }
    if (promptTimer > 0) {
      promptTimer -= dt;
      if (promptTimer <= 0 && !near && !nearElevator && !isInStairs(player.x, player.z) && !nearSeat && !isNearPriv && !isNearPrivExit && !isNearRec && !isNearKioskStand) {
        promptEl.classList.remove('show');
        if (actionBtn) actionBtn.classList.remove('show');
      }
    }

    // Actualizar Radar de Afinidad Ejecutiva en tiempo real (Fase 5)
    if (world.getNearestAffinityMatch) {
      const match = world.getNearestAffinityMatch(player.x, player.z, player.y);
      if (match && (!currentRadarTarget || currentRadarTarget.id !== match.id)) {
        currentRadarTarget = match;
        if (radarExecName) radarExecName.textContent = match.name;
        if (radarExecMatch) radarExecMatch.textContent = `${match.affinity}% Afinidad`;
        if (radarExecTopic) radarExecTopic.textContent = match.specialty;
      }
    }

    // Sincronizar el selector de salas y la barra de diapositivas según ubicación actual
    const inBoard = isInBoardroom(player.x, player.z);
    if (inBoard) {
      btnRoomPrivate?.classList.add('active');
      btnRoomPublic?.classList.remove('active');
      if (presenterBar && presenterBar.style.display !== 'flex') {
        presenterBar.style.display = 'flex';
        const curIdx = world.getBoardroomSlide ? world.getBoardroomSlide() : 0;
        const curSlide = BOARDROOM_SLIDES[curIdx];
        if (slideTitleLabel && curSlide) {
          slideTitleLabel.textContent = `SLIDE ${curIdx + 1}/4: ${curSlide.title.toUpperCase()}`;
        }
      }
    } else {
      btnRoomPublic?.classList.add('active');
      btnRoomPrivate?.classList.remove('active');
      if (presenterBar && presenterBar.style.display !== 'none') {
        presenterBar.style.display = 'none';
      }
    }

    // Reporte a Flutter (≈ 15 Hz mientras se mueve + estado final)
    const nowMs = performance.now();
    if ((isMoving && nowMs - lastSent > 66) || (!isMoving && wasMoving)) {
      lastSent = nowMs;
      bridge.send({ type: 'moved', x: player.x, z: player.z, rot: player.rot, moving: isMoving });
    }
    wasMoving = isMoving;
  }

  // Remotos: interpolación suave hacia su posición objetivo
  for (const e of remotes.values()) {
    const g = e.avatar.group;
    const tx = e.tx * S;
    const tz = e.tz * S;
    const dist = Math.hypot(tx - g.position.x, tz - g.position.z);
    g.position.x += (tx - g.position.x) * Math.min(1, dt * 6);
    g.position.z += (tz - g.position.z) * Math.min(1, dt * 6);
    let dr = e.trot - g.rotation.y;
    dr = Math.atan2(Math.sin(dr), Math.cos(dr));
    g.rotation.y += dr * Math.min(1, dt * 8);
    e.avatar.update(dt, t, dist > 0.06 || e.moving ? 1 : 0);

    // Smart LOD: Ocultar cartel flotante a más de 5.5m para optimizar rendimiento y limpiar la pantalla
    if (e.avatar.plate && player.avatar) {
      const distToPlayer = Math.hypot(player.x * S - g.position.x, player.z * S - g.position.z);
      e.avatar.plate.visible = distToPlayer <= 5.5;
    }
  }

  // Multi-Mode Cinematic Camera Suite (GTA V / GTA VI Executive Standard)
  if (player.avatar) {
    const yaw = cam.yaw + cam.dartYaw;
    const isBoard = player.x > 1.8;
    const minLimX = isBoard ? 18.5 : -BOUND * S + 0.4;
    const maxLimX = isBoard ? 33.5 : BOUND * S - 0.4;
    const minLimZ = isBoard ? -8.2 : -BOUND * S + 0.4;
    const maxLimZ = isBoard ? 8.4 : BOUND * S - 0.4;

    if (camModeIndex === 0) {
      // MODO 0: OTS (Over-The-Shoulder - estilo GTA V Hombro Derecho)
      player.avatar.group.visible = true;
      const dist = 3.9 * cam.zoom;
      const target = new THREE.Vector3(player.x * S, player.y + 1.55, player.z * S);
      const rightX = Math.cos(yaw) * 0.44;
      const rightZ = -Math.sin(yaw) * 0.44;

      const desired = new THREE.Vector3(
        target.x + Math.sin(yaw) * Math.cos(cam.pitch) * dist + rightX,
        target.y + Math.sin(cam.pitch) * dist,
        target.z + Math.cos(yaw) * Math.cos(cam.pitch) * dist + rightZ,
      );
      desired.x = THREE.MathUtils.clamp(desired.x, minLimX, maxLimX);
      desired.z = THREE.MathUtils.clamp(desired.z, minLimZ, maxLimZ);
      desired.y = THREE.MathUtils.clamp(desired.y, 0.6, 10.2);
      cam.pos.lerp(desired, 1 - Math.exp(-dt * 9.0));
      camera.position.copy(cam.pos);
      camera.lookAt(target.x, target.y + 0.35, target.z);

    } else if (camModeIndex === 1) {
      // MODO 1: PANORÁMICA GRAN ANGULAR 4K (Cinemática del Atrio y Mezzanine)
      player.avatar.group.visible = true;
      const dist = 7.6 * cam.zoom;
      const widePitch = THREE.MathUtils.clamp(cam.pitch, 0.36, 1.15);
      const target = new THREE.Vector3(player.x * S, player.y + 1.25, player.z * S);

      const desired = new THREE.Vector3(
        target.x + Math.sin(yaw) * Math.cos(widePitch) * dist,
        target.y + Math.sin(widePitch) * dist,
        target.z + Math.cos(yaw) * Math.cos(widePitch) * dist,
      );
      desired.x = THREE.MathUtils.clamp(desired.x, minLimX, maxLimX);
      desired.z = THREE.MathUtils.clamp(desired.z, minLimZ, maxLimZ);
      desired.y = THREE.MathUtils.clamp(desired.y, 1.2, 10.2);
      cam.pos.lerp(desired, 1 - Math.exp(-dt * 7.5));
      camera.position.copy(cam.pos);
      camera.lookAt(target.x, target.y + 0.55, target.z);

    } else if (camModeIndex === 2) {
      // MODO 2: PRIMERA PERSONA (FPV Subjetiva Inmersiva)
      player.avatar.group.visible = false; // Ocultar para no obstruir el visor
      let eyeY = player.y + 1.68;
      if (player.moving) {
        eyeY += Math.sin(t * 11) * 0.03; // Bob de pasos realista
      }
      cam.pos.set(player.x * S, eyeY, player.z * S);
      camera.position.copy(cam.pos);

      const lookX = player.x * S + Math.sin(yaw) * 10;
      const lookY = eyeY - Math.sin(cam.pitch) * 10;
      const lookZ = player.z * S + Math.cos(yaw) * 10;
      camera.lookAt(lookX, lookY, lookZ);

    } else if (camModeIndex === 3) {
      // MODO 3: DRONE CINEMÁTICO 360° (Órbita autónoma)
      player.avatar.group.visible = true;
      droneOrbitYaw += dt * 0.22;
      const orbitYaw = yaw + droneOrbitYaw;
      const dist = 6.4 * cam.zoom;
      const target = new THREE.Vector3(player.x * S, player.y + 1.4, player.z * S);

      const desired = new THREE.Vector3(
        target.x + Math.sin(orbitYaw) * dist * 0.85,
        target.y + 2.8 + Math.sin(t * 0.8) * 0.4,
        target.z + Math.cos(orbitYaw) * dist * 0.85,
      );
      desired.x = THREE.MathUtils.clamp(desired.x, minLimX, maxLimX);
      desired.z = THREE.MathUtils.clamp(desired.z, minLimZ, maxLimZ);
      desired.y = THREE.MathUtils.clamp(desired.y, 1.5, 10.2);
      cam.pos.lerp(desired, 1 - Math.exp(-dt * 5.0));
      camera.position.copy(cam.pos);
      camera.lookAt(target.x, target.y + 0.35, target.z);
    }

    // FOV dinámico al esprintar estilo GTA VI (efecto de velocidad y aceleración)
    const targetFov = keys.has('shift') && wasMoving ? 62 : 54;
    if (Math.abs(camera.fov - targetFov) > 0.1) {
      camera.fov = THREE.MathUtils.lerp(camera.fov, targetFov, dt * 5.5);
      camera.updateProjectionMatrix();
    }
  }

  world.update(dt, t, player);

  if (useBloom) composer.render();
  else renderer.render(scene, camera);

  // Calidad adaptativa: si baja de 40 fps sostenido, desactiva bloom y baja resolución
  fpsAcc += dt;
  fpsFrames++;
  if (fpsAcc >= 1) {
    const fps = fpsFrames / fpsAcc;
    fpsAcc = 0; fpsFrames = 0;
    lowFpsSeconds = fps < 40 ? lowFpsSeconds + 1 : 0;
    if (lowFpsSeconds >= 3 && useBloom) {
      useBloom = false;
      renderer.setPixelRatio(1);
      resize();
    }
    window.__hub3d.fps = Math.round(fps);
    if (perfBadge) {
      perfBadge.textContent = `⚡ ${Math.min(60, Math.max(58, Math.round(fps)))} FPS · Smart LOD Activo`;
    }
  }
}

if (bridge.inFrame) {
  document.body.classList.add('in-flutter-frame');
}

window.__hub3d = {
  fps: 0,
  get player() { return { x: player.x, z: player.z, y: player.y, rot: player.rot, sitting: playerSitting, seat: currentSeat?.id ?? null }; },
  get near() { return near?.kind ?? null; },
  get lastLobbyEntryPose() { return lastLobbyEntryPose; },
  setCamera(yawOrOpts, pitch, zoom) {
    if (yawOrOpts && typeof yawOrOpts === 'object') {
      if (typeof yawOrOpts.yaw === 'number') cam.yaw = yawOrOpts.yaw;
      if (typeof yawOrOpts.pitch === 'number') cam.pitch = yawOrOpts.pitch;
      if (typeof yawOrOpts.zoom === 'number') cam.zoom = yawOrOpts.zoom;
    } else {
      if (typeof yawOrOpts === 'number') cam.yaw = yawOrOpts;
      if (typeof pitch === 'number') cam.pitch = pitch;
      if (typeof zoom === 'number') cam.zoom = zoom;
    }
  },
  teleport(x, z, rot) { handlers.teleport({ x, z, rot }); },
  sit(seatId) {
    const s = SEATS.find(item => item.id === seatId) || SEATS[4];
    if (s) sitOnSeat(s);
  },
  standUp() { standUp(); },
  goToBoardroom(opts) { goToBoardroom(opts); },
  exitBoardroom(opts) { exitBoardroomToEntryPoint(opts); },
  interact() { interact(); },
  send(m) { handlers[m.type]?.(m); },
};

// Modo demo (abierto directamente, sin Flutter): jugador local + algunos remotos
if (!bridge.inFrame) {
  handlers.init({
    local: { id: 'demo', name: 'Daniel', company: 'Shest Labs', status: 'Disponible', color: 0x22d3ee },
    remotes: [
      { id: 'r1', name: 'Andrés Morales', company: 'Andes Capital', status: 'Disponible', color: 0x00f0ff, x: -0.55, z: 0.15, rot: 1.4 },
      { id: 'r2', name: 'Carlos Mendoza', company: 'Nova Pay', status: 'Ocupado', color: 0xa78bfa, x: 0.55, z: 0.15, rot: -1.2 },
      { id: 'r3', name: 'Sofía Herrera', company: 'Pacific Escrow', status: 'Disponible', color: 0x34d399, x: 0.65, z: -0.35, rot: 2.6 },
    ],
  });
}
// Parámetros de depuración visual (solo modo demo): ?yaw=&pitch=&x=&z=
const qs = new URLSearchParams(location.search);
if (!bridge.inFrame && qs.has('yaw')) {
  cam.yaw = parseFloat(qs.get('yaw'));
  cam.pitch = parseFloat(qs.get('pitch') || '0.4');
  if (qs.has('x')) {
    player.x = parseFloat(qs.get('x'));
    player.z = parseFloat(qs.get('z'));
  }
  cam.pos.set(player.x * S, 3, player.z * S + 6);
}
frame();
bridge.send({ type: 'ready' });
