import * as THREE from 'three';
import { emoteTexture } from './textures.js';

const SKIN = 0xd8a47f;
const HAIR_COLORS = [0x141416, 0x26180b, 0x3b2a1e, 0x1c1917];
const SUIT_COLORS = [0x0d1017, 0x111622, 0x161923, 0x0f131d];
const WORDVERSE_GOLD = 0xd4af37;
const WORDVERSE_LIGHT_GOLD = 0xffd978;

function glowMat(color, k = 2.4) {
  return new THREE.MeshBasicMaterial({
    color: new THREE.Color(color).multiplyScalar(k),
    toneMapped: false,
  });
}

/**
 * Avatar Humanoide Ejecutivo realista (Anatomía esbelta estilo GTA V).
 * - Traje formal entallado con solapa y corbata
 * - Visor VR ergonómico horizontal con glow de neón en visor
 * - Proporciones anatómicas humanas de 1.80m
 */
export function createAvatar({
  id,
  name,
  company,
  status,
  colorHex = 0x22d3ee,
  isLocal = false,
  pose = 'standing', // 'standing' | 'sitting' | 'tablet'
}) {
  const accent = new THREE.Color(colorHex);
  const root = new THREE.Group();
  root.name = `avatar_${id}`;
  root.castShadow = true;

  const body = new THREE.Group();
  root.add(body);

  const suitColor = isLocal ? 0x0a0d14 : SUIT_COLORS[Math.abs(id.hashCode?.() || 0) % SUIT_COLORS.length];
  const suitMat = new THREE.MeshStandardMaterial({
    color: suitColor,
    roughness: 0.36,
    metalness: 0.32,
  });
  const goldExecMat = new THREE.MeshStandardMaterial({
    color: WORDVERSE_GOLD,
    roughness: 0.18,
    metalness: 0.94,
  });
  const shirtMat = new THREE.MeshStandardMaterial({
    color: 0xf8fafc,
    roughness: 0.45,
  });
  const tieMat = new THREE.MeshStandardMaterial({
    color: isLocal ? WORDVERSE_GOLD : 0xb48a28,
    roughness: 0.28,
    metalness: 0.65,
  });
  const skinMat = new THREE.MeshStandardMaterial({
    color: SKIN,
    roughness: 0.62,
    metalness: 0.05,
  });
  const shoeMat = new THREE.MeshStandardMaterial({
    color: 0x070709,
    roughness: 0.18,
    metalness: 0.65,
  });

  // 1. Zapatos de vestir
  const shoeGeo = new THREE.BoxGeometry(0.11, 0.08, 0.24);

  // 2. Piernas anatómicas esbeltas con articulación de rodilla para sentarse
  const legL = new THREE.Group();
  const legR = new THREE.Group();
  const kneeL = new THREE.Group();
  const kneeR = new THREE.Group();
  const thighGeo = new THREE.CylinderGeometry(0.075, 0.065, 0.44, 12);
  const calfGeo = new THREE.CylinderGeometry(0.065, 0.055, 0.44, 12);

  for (const [leg, knee, x] of [[legL, kneeL, -0.11], [legR, kneeR, 0.11]]) {
    leg.position.set(x, 0.88, 0);

    const thigh = new THREE.Mesh(thighGeo, suitMat);
    thigh.position.y = -0.22;
    thigh.castShadow = true;
    leg.add(thigh);

    knee.position.set(0, -0.44, 0);
    leg.add(knee);

    const calf = new THREE.Mesh(calfGeo, suitMat);
    calf.position.y = -0.22;
    calf.castShadow = true;
    knee.add(calf);

    const shoe = new THREE.Mesh(shoeGeo, shoeMat);
    shoe.position.set(0, -0.42, 0.04);
    shoe.castShadow = true;
    knee.add(shoe);

    body.add(leg);
  }

  // 3. Torso y Saco de vestir entallado
  const torsoGroup = new THREE.Group();
  torsoGroup.position.y = 1.18;
  body.add(torsoGroup);

  const chest = new THREE.Mesh(
    new THREE.CylinderGeometry(0.20, 0.16, 0.58, 12),
    suitMat,
  );
  chest.scale.set(1.15, 1, 0.75); // Silueta esbelta
  chest.castShadow = true;
  torsoGroup.add(chest);

  // Pechera de camisa blanca y corbata
  const shirtFront = new THREE.Mesh(
    new THREE.PlaneGeometry(0.12, 0.38),
    shirtMat,
  );
  shirtFront.position.set(0, 0.08, 0.126);
  torsoGroup.add(shirtFront);

  const tie = new THREE.Mesh(
    new THREE.BoxGeometry(0.038, 0.32, 0.01),
    tieMat,
  );
  tie.position.set(0, 0.04, 0.133);
  torsoGroup.add(tie);

  // Pisacorbata metálico cromado de lujo
  const tieClip = new THREE.Mesh(
    new THREE.BoxGeometry(0.036, 0.008, 0.008),
    new THREE.MeshStandardMaterial({ color: 0xe2e8f0, roughness: 0.15, metalness: 0.95 }),
  );
  tieClip.position.set(0, 0.07, 0.141);
  torsoGroup.add(tieClip);

  // Cuello de camisa ejecutiva en pico
  const collarL = new THREE.Mesh(new THREE.BoxGeometry(0.035, 0.045, 0.012), shirtMat);
  collarL.position.set(-0.042, 0.23, 0.126);
  collarL.rotation.z = -0.38;
  const collarR = new THREE.Mesh(new THREE.BoxGeometry(0.035, 0.045, 0.012), shirtMat);
  collarR.position.set(0.042, 0.23, 0.126);
  collarR.rotation.z = 0.38;
  torsoGroup.add(collarL, collarR);

  // Solapas ejecutivas del saco (lapels) con satinado corporativo
  const lapelMat = new THREE.MeshStandardMaterial({
    color: suitColor,
    roughness: 0.35,
    metalness: 0.35,
  });
  const lapelL = new THREE.Mesh(new THREE.BoxGeometry(0.055, 0.30, 0.015), lapelMat);
  lapelL.position.set(-0.065, 0.08, 0.134);
  lapelL.rotation.z = -0.15;
  const lapelR = new THREE.Mesh(new THREE.BoxGeometry(0.055, 0.30, 0.015), lapelMat);
  lapelR.position.set(0.065, 0.08, 0.134);
  lapelR.rotation.z = 0.15;
  torsoGroup.add(lapelL, lapelR);

  // Pin metálico VIP oficial WORDVERSE en oro pulido en la solapa izquierda + pañuelo dorado
  const lapelPin = new THREE.Mesh(
    new THREE.CylinderGeometry(0.013, 0.013, 0.008, 12),
    goldExecMat
  );
  lapelPin.rotation.x = Math.PI / 2;
  lapelPin.position.set(-0.068, 0.15, 0.144);
  torsoGroup.add(lapelPin);

  // Pañuelo ejecutivo dorado (pocket square) y botones dorados de saco
  const pocketSquare = new THREE.Mesh(
    new THREE.BoxGeometry(0.042, 0.016, 0.008),
    goldExecMat
  );
  pocketSquare.position.set(0.078, 0.11, 0.132);
  pocketSquare.rotation.z = -0.12;
  torsoGroup.add(pocketSquare);

  for (const by of [-0.06, -0.14]) {
    const suitBtn = new THREE.Mesh(
      new THREE.CylinderGeometry(0.009, 0.009, 0.008, 10),
      goldExecMat
    );
    suitBtn.rotation.x = Math.PI / 2;
    suitBtn.position.set(0, by, 0.136);
    torsoGroup.add(suitBtn);
  }

  // Filete dorado en los hombros (charretera ejecutiva sutil WordVerse)
  for (const sx of [-0.14, 0.14]) {
    const shoulderTrim = new THREE.Mesh(
      new THREE.BoxGeometry(0.075, 0.008, 0.045),
      goldExecMat
    );
    shoulderTrim.position.set(sx, 0.275, 0);
    torsoGroup.add(shoulderTrim);
  }

  // Cuello
  const neck = new THREE.Mesh(
    new THREE.CylinderGeometry(0.052, 0.062, 0.12, 12),
    skinMat,
  );
  neck.position.y = 1.52;
  body.add(neck);

  // 4. Cabeza humana estilizada, cabello ejecutivo y Gafas AR con montura de Oro WordVerse
  const headGroup = new THREE.Group();
  headGroup.position.y = 1.66;
  body.add(headGroup);

  const head = new THREE.Mesh(
    new THREE.SphereGeometry(0.112, 20, 16),
    skinMat,
  );
  head.scale.set(0.96, 1.14, 0.98);
  head.castShadow = true;
  headGroup.add(head);

  // Cabello ejecutivo esculpido con volumen superior
  const hairIdx = Math.abs((name || id || '').length) % HAIR_COLORS.length;
  const hairMat = new THREE.MeshStandardMaterial({ color: HAIR_COLORS[hairIdx], roughness: 0.72, metalness: 0.12 });
  const hair = new THREE.Mesh(
    new THREE.SphereGeometry(0.118, 16, 12, 0, Math.PI * 2, 0, Math.PI * 0.56),
    hairMat,
  );
  hair.scale.set(0.98, 1.08, 1.02);
  hair.rotation.x = -0.24;
  headGroup.add(hair);

  // Gafas AR Smart Glasses ejecutivas con puente y bisel en Oro WordVerse (#D4AF37)
  const visorBody = new THREE.Mesh(
    new THREE.BoxGeometry(0.192, 0.038, 0.055),
    new THREE.MeshStandardMaterial({ color: 0x070709, roughness: 0.15, metalness: 0.9 }),
  );
  visorBody.position.set(0, 0.015, 0.092);
  headGroup.add(visorBody);

  const visorGoldBrow = new THREE.Mesh(
    new THREE.BoxGeometry(0.20, 0.008, 0.06),
    goldExecMat,
  );
  visorGoldBrow.position.set(0, 0.036, 0.094);
  headGroup.add(visorGoldBrow);

  const visorGlow = new THREE.Mesh(
    new THREE.BoxGeometry(0.174, 0.020, 0.008),
    glowMat(isLocal ? WORDVERSE_LIGHT_GOLD : colorHex, 2.2),
  );
  visorGlow.position.set(0, 0.014, 0.122);
  headGroup.add(visorGlow);

  // 5. Brazos articulados en hombros con hombreras estructuradas
  const armL = new THREE.Group();
  const armR = new THREE.Group();
  const upperArmGeo = new THREE.CylinderGeometry(0.052, 0.048, 0.36, 10);
  const forearmGeo = new THREE.CylinderGeometry(0.048, 0.042, 0.34, 10);
  const handGeo = new THREE.SphereGeometry(0.042, 10, 8);
  const shoulderGeo = new THREE.SphereGeometry(0.065, 8, 8);

  for (const [arm, x] of [[armL, -0.24], [armR, 0.24]]) {
    arm.position.set(x, 1.44, 0);

    const shoulder = new THREE.Mesh(shoulderGeo, suitMat);
    shoulder.scale.set(1.15, 0.8, 1.15);
    arm.add(shoulder);

    const upper = new THREE.Mesh(upperArmGeo, suitMat);
    upper.position.y = -0.18;
    upper.castShadow = true;
    arm.add(upper);

    const fore = new THREE.Mesh(forearmGeo, suitMat);
    fore.position.y = -0.48;
    fore.castShadow = true;
    arm.add(fore);

    const hand = new THREE.Mesh(handGeo, skinMat);
    hand.position.y = -0.68;
    arm.add(hand);

    body.add(arm);
  }

  // Caída natural de brazos a los costados
  armL.rotation.z = 0.06;
  armR.rotation.z = -0.06;

  // Reloj ejecutivo con bisel dorado en la muñeca izquierda
  const watchMat = new THREE.MeshStandardMaterial({ color: 0xd4af37, roughness: 0.2, metalness: 0.9 });
  const watch = new THREE.Mesh(new THREE.CylinderGeometry(0.049, 0.049, 0.024, 12), watchMat);
  watch.position.set(0, -0.62, 0);
  armL.add(watch);

  // Mancuernillas / gemelos en oro en los puños
  const cufflinkMat = new THREE.MeshStandardMaterial({ color: 0xd4af37, roughness: 0.15, metalness: 0.95 });
  const cuffL = new THREE.Mesh(new THREE.BoxGeometry(0.016, 0.008, 0.012), cufflinkMat);
  cuffL.position.set(0.042, -0.60, 0);
  armL.add(cuffL);
  const cuffR = new THREE.Mesh(new THREE.BoxGeometry(0.016, 0.008, 0.012), cufflinkMat);
  cuffR.position.set(-0.042, -0.60, 0);
  armR.add(cuffR);

  // Tablet holográfica en la mano si corresponde
  let tablet = null;
  if (isLocal || pose === 'tablet') {
    tablet = new THREE.Mesh(
      new THREE.BoxGeometry(0.18, 0.24, 0.01),
      new THREE.MeshBasicMaterial({
        color: new THREE.Color(0x38bdf8).multiplyScalar(1.8),
        transparent: true,
        opacity: 0.75,
        toneMapped: false,
      }),
    );
    tablet.position.set(0.04, -0.66, 0.14);
    tablet.rotation.x = -0.85;
    tablet.rotation.y = -0.2;
    armR.add(tablet);
  }

  // 6. Anillo de presencia sutil en el piso en Oro WordVerse (o acento)
  const ring = new THREE.Mesh(
    new THREE.RingGeometry(0.34, 0.39, 32),
    new THREE.MeshBasicMaterial({
      color: isLocal ? WORDVERSE_GOLD : accent,
      transparent: true,
      opacity: isLocal ? 0.82 : 0.42,
      side: THREE.DoubleSide,
      toneMapped: false,
    }),
  );
  ring.rotation.x = -Math.PI / 2;
  ring.position.y = 0.02;
  root.add(ring);

  // Sombra de contacto suave en el suelo (Ground Ambient Occlusion estilo GTA VI)
  const shadowCanvas = document.createElement('canvas');
  shadowCanvas.width = 128;
  shadowCanvas.height = 128;
  const sCtx = shadowCanvas.getContext('2d');
  const sGrad = sCtx.createRadialGradient(64, 64, 8, 64, 64, 60);
  sGrad.addColorStop(0, 'rgba(0, 8, 20, 0.72)');
  sGrad.addColorStop(0.5, 'rgba(0, 8, 20, 0.30)');
  sGrad.addColorStop(1, 'rgba(0, 8, 20, 0)');
  sCtx.fillStyle = sGrad;
  sCtx.fillRect(0, 0, 128, 128);

  const shadowTex = new THREE.CanvasTexture(shadowCanvas);
  const contactShadow = new THREE.Mesh(
    new THREE.PlaneGeometry(0.9, 0.9),
    new THREE.MeshBasicMaterial({
      map: shadowTex,
      transparent: true,
      depthWrite: false,
    }),
  );
  contactShadow.rotation.x = -Math.PI / 2;
  contactShadow.position.y = 0.006;
  root.add(contactShadow);

  // Nameplate flotante compacto y elegante en Negro Obsidiana + Oro WordVerse (#D4AF37)
  let plate = null;
  function renderNameplateCanvas(pName, pCompany) {
    const canvas = document.createElement('canvas');
    canvas.width = 360;
    canvas.height = 96;
    const ctx = canvas.getContext('2d');

    // Fondo cápsula ejecutiva en Negro Obsidiana con borde Dorado WordVerse
    ctx.fillStyle = 'rgba(10, 10, 14, 0.92)';
    ctx.beginPath();
    ctx.roundRect ? ctx.roundRect(6, 6, 348, 84, 18) : ctx.rect(6, 6, 348, 84);
    ctx.fill();
    ctx.strokeStyle = '#d4af37';
    ctx.lineWidth = 2.5;
    ctx.stroke();

    // Subtítulo superior de compañía en Oro Luminoso
    ctx.textAlign = 'center';
    ctx.fillStyle = '#ffd978';
    ctx.font = '700 15px "Segoe UI", Arial, sans-serif';
    const compText = (pCompany || 'WORDVERSE VIP').toUpperCase();
    ctx.fillText(compText.length > 26 ? compText.slice(0, 26) + '…' : compText, 180, 32);

    // Línea divisoria dorada sutil
    ctx.strokeStyle = 'rgba(212, 175, 55, 0.32)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(42, 42);
    ctx.lineTo(318, 42);
    ctx.stroke();

    // Nombre del Avatar Ejecutivo compacto y nítido
    ctx.fillStyle = '#ffffff';
    ctx.font = '800 24px "Segoe UI", Arial, sans-serif';
    const cleanName = pName.length > 20 ? pName.slice(0, 20) + '…' : pName;
    ctx.fillText((isLocal ? '⭐ ' : '') + cleanName, 174, 71);

    // Punto indicador de estado online
    ctx.fillStyle = '#00ff87';
    ctx.beginPath();
    ctx.arc(324, 63, 5.5, 0, Math.PI * 2);
    ctx.fill();
    return canvas;
  }

  if (name) {
    const canvas = renderNameplateCanvas(name, company);
    const tex = new THREE.CanvasTexture(canvas);
    plate = new THREE.Sprite(
      new THREE.SpriteMaterial({ map: tex, transparent: true, depthWrite: false }),
    );
    // Escala compacta (~45% más pequeña que antes) para no saturar la vista
    plate.scale.set(0.68, 0.18, 1);
    plate.position.y = 2.04;
    if (isLocal) {
      plate.visible = false;
    }
    root.add(plate);
  }

  // Sprite dinámico de Emote / Reacción rápida (👋, 👍, 🤝, etc.)
  let emoteSprite = null;
  let emoteTimer = 0;

  // 7. Halo Holográfico de Audio Espacial (Speaking Waves) en Oro y Cian
  const speakingGroup = new THREE.Group();
  speakingGroup.position.set(0, 1.96, 0);
  speakingGroup.visible = false;
  root.add(speakingGroup);

  const waveRing1 = new THREE.Mesh(
    new THREE.TorusGeometry(0.18, 0.012, 8, 36),
    new THREE.MeshBasicMaterial({
      color: 0x38bdf8,
      transparent: true,
      opacity: 0.85,
      toneMapped: false,
    }),
  );
  waveRing1.rotation.x = Math.PI / 2;

  const waveRing2 = new THREE.Mesh(
    new THREE.TorusGeometry(0.26, 0.010, 8, 36),
    new THREE.MeshBasicMaterial({
      color: WORDVERSE_GOLD,
      transparent: true,
      opacity: 0.70,
      toneMapped: false,
    }),
  );
  waveRing2.rotation.x = Math.PI / 2;

  const waveRing3 = new THREE.Mesh(
    new THREE.TorusGeometry(0.34, 0.008, 8, 36),
    new THREE.MeshBasicMaterial({
      color: 0x00ff87,
      transparent: true,
      opacity: 0.55,
      toneMapped: false,
    }),
  );
  waveRing3.rotation.x = Math.PI / 2;

  const micCanvas = document.createElement('canvas');
  micCanvas.width = 128;
  micCanvas.height = 128;
  const mCtx = micCanvas.getContext('2d');
  mCtx.fillStyle = 'rgba(10, 10, 16, 0.88)';
  mCtx.beginPath();
  mCtx.arc(64, 64, 52, 0, Math.PI * 2);
  mCtx.fill();
  mCtx.strokeStyle = '#00f0ff';
  mCtx.lineWidth = 4;
  mCtx.stroke();
  mCtx.font = '54px sans-serif';
  mCtx.textAlign = 'center';
  mCtx.textBaseline = 'middle';
  mCtx.fillText('🎙️', 64, 66);
  const micTex = new THREE.CanvasTexture(micCanvas);
  const micSprite = new THREE.Sprite(
    new THREE.SpriteMaterial({ map: micTex, transparent: true, depthWrite: false }),
  );
  micSprite.scale.set(0.18, 0.18, 1);
  micSprite.position.set(0, 0.22, 0);

  speakingGroup.add(waveRing1, waveRing2, waveRing3, micSprite);

  const state = {
    walkTime: 0,
    intensity: 0,
    isSitting: pose === 'sitting',
    activeGesture: null,
    gestureTimer: 0,
    isSpeaking: false,
    speakingVolume: 0,
  };

  if (state.isSitting) {
    legL.rotation.x = -Math.PI / 2;
    legR.rotation.x = -Math.PI / 2;
    kneeL.rotation.x = Math.PI / 2;
    kneeR.rotation.x = Math.PI / 2;
    body.position.y = -0.34;
    torsoGroup.rotation.x = 0;
    headGroup.rotation.x = 0;
    armL.rotation.x = -0.52;
    armR.rotation.x = -0.58;
    armL.rotation.z = 0.14;
    armR.rotation.z = -0.14;
  }

  const api = {
    id,
    name,
    company,
    status,
    isLocal,
    colorHex,
    group: root,
    plate,
    hitTargets: [chest, head],
    setSpeaking(speaking, volume = 1.0) {
      state.isSpeaking = !!speaking;
      state.speakingVolume = volume;
      speakingGroup.visible = state.isSpeaking;
    },
    setPlate({ name: newName, company: newComp }) {
      if (!plate || !newName) return;
      const newCanvas = renderNameplateCanvas(newName, newComp);
      if (plate.material.map) plate.material.map.dispose();
      plate.material.map = new THREE.CanvasTexture(newCanvas);
      plate.material.needsUpdate = true;
    },
    playGesture(type) {
      state.activeGesture = type; // 'wave' | 'clap' | 'handshake'
      state.gestureTimer = 3.2;
    },
    showEmote(text) {
      if (emoteSprite) {
        root.remove(emoteSprite);
        if (emoteSprite.material.map) emoteSprite.material.map.dispose();
        emoteSprite.material.dispose();
        emoteSprite = null;
      }
      if (!text) return;

      // Disparador de cinemática gestual sincronizado
      if (text.includes('👋')) {
        this.playGesture('wave');
      } else if (text.includes('👏') || text.includes('👍')) {
        this.playGesture('clap');
      } else if (text.includes('🤝')) {
        this.playGesture('handshake');
      }

      const tex = emoteTexture(text);
      emoteSprite = new THREE.Sprite(
        new THREE.SpriteMaterial({ map: tex, transparent: true, depthWrite: false }),
      );
      emoteSprite.scale.set(0.95, 0.30, 1);
      emoteSprite.position.set(0, 2.34, 0); // Flota directamente sobre el nameplate compacto
      root.add(emoteSprite);
      emoteTimer = 4.0;
    },
    setSitting(sit) {
      state.isSitting = sit;
      state.intensity = 0;
      state.walkTime = 0;
      torsoGroup.rotation.x = 0;
      headGroup.rotation.x = 0;
      if (sit) {
        speakingGroup.position.y = 1.62;
        // Muslos hacia adelante a 90 grados apoyados exactamente sobre el cojín (y = 0.54m)
        legL.rotation.x = -Math.PI / 2;
        legR.rotation.x = -Math.PI / 2;
        // Pantorrillas verticales a 90 grados con zapatos apoyados sobre el suelo
        kneeL.rotation.x = Math.PI / 2;
        kneeR.rotation.x = Math.PI / 2;
        body.position.y = -0.34;
        // Brazos y manos en postura ejecutiva sobre la mesa (sin atravesar el tablero)
        armL.rotation.x = -0.52;
        armR.rotation.x = -0.58;
        armL.rotation.z = 0.14;
        armR.rotation.z = -0.14;
        if (plate) plate.position.y = 1.72;
      } else {
        speakingGroup.position.y = 1.96;
        legL.rotation.x = 0;
        legR.rotation.x = 0;
        kneeL.rotation.x = 0;
        kneeR.rotation.x = 0;
        body.position.y = 0;
        armL.rotation.x = 0.04;
        armR.rotation.x = 0.04;
        armL.rotation.z = 0.06;
        armR.rotation.z = -0.06;
        if (plate) plate.position.y = 2.04;
      }
    },
    update(dt, t, moving) {
      if (state.isSpeaking) {
        speakingGroup.visible = true;
        const waveT = t * 14;
        const pulse1 = (Math.sin(waveT) + 1) * 0.5;
        const pulse2 = (Math.sin(waveT + 1.2) + 1) * 0.5;
        const pulse3 = (Math.sin(waveT + 2.4) + 1) * 0.5;

        waveRing1.scale.setScalar(0.85 + pulse1 * 0.35);
        waveRing1.material.opacity = 0.3 + pulse1 * 0.6;
        waveRing1.position.y = pulse1 * 0.05;

        waveRing2.scale.setScalar(0.9 + pulse2 * 0.3);
        waveRing2.material.opacity = 0.2 + pulse2 * 0.6;
        waveRing2.position.y = pulse2 * 0.07;

        waveRing3.scale.setScalar(0.95 + pulse3 * 0.25);
        waveRing3.material.opacity = 0.15 + pulse3 * 0.55;
        waveRing3.position.y = pulse3 * 0.09;

        micSprite.position.y = 0.22 + Math.sin(t * 6) * 0.03;
        if (visorGlow.material.color) visorGlow.material.color.setHex(0x00ff87);
      } else {
        speakingGroup.visible = false;
        if (visorGlow.material.color) visorGlow.material.color.copy(isLocal ? new THREE.Color(WORDVERSE_LIGHT_GOLD) : accent);
      }

      if (emoteSprite) {
        emoteTimer -= dt;
        if (emoteTimer <= 0) {
          root.remove(emoteSprite);
          if (emoteSprite.material.map) emoteSprite.material.map.dispose();
          emoteSprite.material.dispose();
          emoteSprite = null;
        } else {
          const baseEmoteY = state.isSitting ? 2.02 : 2.34;
          emoteSprite.position.y = baseEmoteY + Math.sin(t * 4.5) * 0.03;
        }
      }

      // Respiración ejecutiva sutil activa tanto de pie como sentado
      const breath = Math.sin(t * 2.2) * 0.012;
      torsoGroup.scale.set(1.15 * (1 + breath * 0.4), 1 + breath, 0.75 * (1 + breath * 0.5));
      headGroup.position.y = 1.66 + breath * 0.3;

      if (state.isSitting) {
        // Mantener postura sentada perfecta en piernas y pelvis
        body.position.y = -0.34;
        legL.rotation.x = -Math.PI / 2;
        legR.rotation.x = -Math.PI / 2;
        kneeL.rotation.x = Math.PI / 2;
        kneeR.rotation.x = Math.PI / 2;
        torsoGroup.rotation.x = THREE.MathUtils.lerp(torsoGroup.rotation.x, 0, dt * 8.0);
        headGroup.rotation.x = THREE.MathUtils.lerp(headGroup.rotation.x, 0, dt * 8.0);

        // Soportar gestos sociales (saludo, aplauso, apretón) mientras está sentado
        if (state.activeGesture && state.gestureTimer > 0) {
          state.gestureTimer -= dt;
          if (state.activeGesture === 'wave') {
            armR.rotation.x = -2.15 + Math.sin(t * 11) * 0.22;
            armR.rotation.z = -0.42;
            armL.rotation.x = -0.52;
            armL.rotation.z = 0.14;
          } else if (state.activeGesture === 'clap') {
            armL.rotation.x = -1.25;
            armR.rotation.x = -1.25;
            armL.rotation.z = Math.sin(t * 14) * 0.12 + 0.28;
            armR.rotation.z = -Math.sin(t * 14) * 0.12 - 0.28;
          } else if (state.activeGesture === 'handshake') {
            armR.rotation.x = -1.35;
            armR.rotation.z = -0.15 + Math.sin(t * 6) * 0.05;
            armL.rotation.x = -0.52;
            armL.rotation.z = 0.14;
          }
        } else {
          state.activeGesture = null;
          armL.rotation.x = -0.52 + Math.sin(t * 1.5) * 0.015;
          armR.rotation.x = -0.58 - Math.sin(t * 1.5) * 0.015;
          armL.rotation.z = 0.14;
          armR.rotation.z = -0.14;
        }
        ring.material.opacity = isLocal ? 0.65 + Math.sin(t * 3) * 0.15 : 0.30;
        return;
      }

      // 1. Cinemática de Columna y Tronco estilo GTA V (inclinación biomecánica al correr)
      const forwardLean = moving > 1.0 ? 0.15 : (moving > 0.05 ? 0.05 : 0);
      torsoGroup.rotation.x = THREE.MathUtils.lerp(torsoGroup.rotation.x, forwardLean, dt * 7.5);
      headGroup.rotation.x = THREE.MathUtils.lerp(headGroup.rotation.x, -forwardLean * 0.75, dt * 7.5);

      state.intensity += (moving - state.intensity) * Math.min(1, dt * 10);
      const isRunning = state.intensity > 1.0;
      state.walkTime += dt * (isRunning ? 11.2 : 8.5) * state.intensity;

      const swingMagnitude = isRunning ? 0.88 : 0.65;
      const swing = Math.sin(state.walkTime) * swingMagnitude * state.intensity;
      legL.rotation.x = swing;
      legR.rotation.x = -swing;

      // 3. Cinemática de Brazos y Gestos Sociales en Vivo
      if (state.activeGesture && state.gestureTimer > 0) {
        state.gestureTimer -= dt;
        if (state.activeGesture === 'wave') {
          // Saludo cordial levantando la mano derecha
          armR.rotation.x = -2.15 + Math.sin(t * 11) * 0.22;
          armR.rotation.z = -0.42;
          armL.rotation.x = 0.04;
          armL.rotation.z = 0.06;
        } else if (state.activeGesture === 'clap') {
          // Aplauso ejecutivo con ambas manos al frente
          armL.rotation.x = -1.25;
          armR.rotation.x = -1.25;
          armL.rotation.z = Math.sin(t * 14) * 0.12 + 0.28;
          armR.rotation.z = -Math.sin(t * 14) * 0.12 - 0.28;
        } else if (state.activeGesture === 'handshake') {
          // Estrechar la mano con brazo extendido
          armR.rotation.x = -1.35;
          armR.rotation.z = -0.15 + Math.sin(t * 6) * 0.05;
          armL.rotation.x = 0.04;
          armL.rotation.z = 0.06;
        }
      } else {
        state.activeGesture = null;
        if (state.intensity > 0.05) {
          armL.rotation.x = -swing * 0.75;
          armL.rotation.z = 0.06 + Math.abs(swing) * 0.06;
          if (!tablet) {
            armR.rotation.x = swing * 0.75;
            armR.rotation.z = -0.06 - Math.abs(swing) * 0.06;
          } else {
            armR.rotation.x = -0.35 + Math.sin(t * 1.5) * 0.03;
          }
        } else {
          // Postura natural de reposo
          armL.rotation.x = 0.04 + Math.sin(t * 1.6) * 0.02;
          armL.rotation.z = 0.06;
          if (!tablet) {
            armR.rotation.x = 0.04 - Math.sin(t * 1.6) * 0.02;
            armR.rotation.z = -0.06;
          } else {
            armR.rotation.x = -0.35 + Math.sin(t * 1.5) * 0.03;
          }
        }
      }

      body.position.y = Math.abs(Math.sin(state.walkTime)) * (isRunning ? 0.065 : 0.04) * state.intensity;
      ring.material.opacity = isLocal ? 0.7 + Math.sin(t * 3) * 0.2 : 0.35;
    },
    dispose() {
      if (emoteSprite) {
        if (emoteSprite.material.map) emoteSprite.material.map.dispose();
        emoteSprite.material.dispose();
      }
      root.traverse((o) => {
        if (o.geometry) o.geometry.dispose();
        if (o.material) {
          if (o.material.map) o.material.map.dispose();
          o.material.dispose();
        }
      });
    },
  };

  root.userData.avatar = api;
  chest.userData.avatar = api;
  head.userData.avatar = api;
  return api;
}
