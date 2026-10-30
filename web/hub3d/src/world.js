import * as THREE from 'three';
import { playDoorServo, playElevatorChime } from './audio.js?v=20261029_v6';
import { createAvatar } from './avatars.js?v=20261029_v6';
import {
  BOARDROOM_CENTER, BOARDROOM_RADIUS, BOARDROOM_TABLE_R, BOXES, ELEVATOR, PILLARS,
  SEATS, TABLE_R, WORLD_SCALE as S,
} from './physics.js?v=20261029_v6';
import {
  backlitOnyxTexture, biometricAiScreenTexture, BOARDROOM_SLIDES, boardroomHoloMapTexture,
  boardroomSlideTexture, canvasTexture,
  carbonFiberTexture, curvedCommandCenterMapTexture, drawLogo, flutedWoodTexture,
  hotspotLabelTexture, panoramicSkylineTexture, premionCornerPillarTexture, premionEmblemTexture,
  premionPortalSignTexture, premionWallGoldPanelTexture, quiltedLeatherTexture, registryTexture,
  particleGlowTexture, royalMarblePbrTexture, signTexture, tickerCardTexture, valeriaMendezBadgeTexture,
  wordverseCentralDrumTexture, wordverseFloorMatTexture, worldMapTexture,
} from './textures.js?v=20261029_v6';

// =========================================================================
// PALETA OFICIAL PREMION 3D BUSINESS ROOM (Exacta al Concept Art Oficial)
// =========================================================================
const NEGRO_OBSIDIANA = 0x0a0a0c; // #0A0A0C
const ORO_PREMIUM = 0xd4af37;     // #D4AF37
const ORO_LUMINOSO = 0xffd978;    // #FFD978
const ORO_OSCURO = 0x8c6422;      // #8C6422
const CIAN_HOLO = 0x00f0ff;       // #00F0FF
const PURPURA_NEB = 0x7b2cbf;     // #7B2CBF
const VERDE_ESMERALDA = 0x00ff87; // #00FF87

const TOTAL_H = 10.8; // Altura monumental ampliada para los dos niveles
const HALF = 9.0; // Sala principal ampliada (18m x 18m = BOUND * S)
const MEZZANINE_Y = 4.2; // Altura de la planta alta
const CYAN = 0x22d3ee;
const GLOW_BLUE = 0x38bdf8;

function glow(color, k = 2.2) {
  return new THREE.MeshBasicMaterial({
    color: new THREE.Color(color).multiplyScalar(k),
    toneMapped: false,
  });
}

function box(w, h, d, mat, x, y, z, castShadow = true, receiveShadow = true) {
  const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat);
  m.position.set(x, y, z);
  m.castShadow = castShadow;
  m.receiveShadow = receiveShadow;
  return m;
}

/**
 * Escena Arquitectónica WordVerse Global Business Hub (Fidelidad de la Imagen).
 * - Estructura de 2 niveles: Mezzanine con pasarela y barandillas de vidrio.
 * - Suelo de concreto arquitectónico claro pulido.
 * - Sala de Reuniones Pública (arriba a la izquierda, con ventanales de piso a techo y ejecutivos en junta).
 * - Sala de Reuniones Privada (abajo a la izquierda, puerta corrediza esmerilada).
 * - Gran Cilindro LED central suspendido "WORDVERSE GLOBAL BUSINESS HUB".
 * - Recepción curva blanca/neón abajo a la derecha y kiosco interactivo.
 */
export function buildWorld(scene, { hotspots, accent = CYAN }) {
  const root = new THREE.Group();
  root.name = 'hub_realistic_world';
  scene.add(root);

  const animated = [];
  const accentMats = [];
  const interactables = [];
  const allNpcAvatars = [];

  const obsidianMat = new THREE.MeshStandardMaterial({
    color: NEGRO_OBSIDIANA,
    roughness: 0.14,
    metalness: 0.85,
  });
  const goldTrimMat = new THREE.MeshStandardMaterial({
    color: ORO_PREMIUM,
    roughness: 0.22,
    metalness: 0.95,
  });

  // =========================================================================
  // 1. ILUMINACIÓN CORPORATIVA PREMION (Paleta Oficial Negro Obsidiana y Neón)
  // Optimizado para 60 FPS sin lag (Sombras a 1024 y luz ambiental atmosférica)
  // =========================================================================
  const hemiLight = new THREE.HemisphereLight(0x3a2c14, 0x0a0a0c, 0.58);
  root.add(hemiLight);

  // Luz principal en Oro Cálido WordVerse
  const dirLight = new THREE.DirectionalLight(0xfff4d6, 0.88);
  dirLight.position.set(4, 15, 6);
  dirLight.castShadow = true;
  dirLight.shadow.mapSize.width = 1024;
  dirLight.shadow.mapSize.height = 1024;
  dirLight.shadow.camera.near = 0.5;
  dirLight.shadow.camera.far = 34;
  dirLight.shadow.camera.left = -HALF - 1;
  dirLight.shadow.camera.right = HALF + 1;
  dirLight.shadow.camera.top = HALF + 1;
  dirLight.shadow.camera.bottom = -HALF - 1;
  dirLight.shadow.bias = -0.0005;
  root.add(dirLight);

  // Foco puntual cálido-dorado y cian en el cilindro central
  const coreLight = new THREE.PointLight(ORO_LUMINOSO, 38, 20, 1.6);
  coreLight.position.set(0, 4.8, 0);
  root.add(coreLight);

  // =========================================================================
  // 2. SUELO DE MÁRMOL REAL CALACATTA & NERO MARQUINA 2K (Estándar GTA VI)
  // =========================================================================
  const marbleTexture = royalMarblePbrTexture({ w: 2048, h: 2048, tileCount: 8 });

  const floorMat = new THREE.MeshStandardMaterial({
    map: marbleTexture,
    roughness: 0.12, // Brillo especular y nitidez de reflejos estilo rascacielos AAA
    metalness: 0.35,
    envMapIntensity: 1.6,
  });

  const floorGround = new THREE.Mesh(
    new THREE.PlaneGeometry(HALF * 2, HALF * 2),
    floorMat,
  );
  floorGround.rotation.x = -Math.PI / 2;
  floorGround.receiveShadow = true;
  root.add(floorGround);

  // Haces de luz volumétrica cenitales (God Rays) desde el domo superior
  const beamGeo = new THREE.CylinderGeometry(1.6, 4.2, 7.8, 32, 1, true);
  const beamMat = new THREE.MeshBasicMaterial({
    color: 0x38bdf8,
    transparent: true,
    opacity: 0.07,
    blending: THREE.AdditiveBlending,
    side: THREE.DoubleSide,
    depthWrite: false,
  });
  const lightBeam = new THREE.Mesh(beamGeo, beamMat);
  lightBeam.position.set(0, 5.8, 0);
  root.add(lightBeam);

  // =========================================================================
  // 1B. PARTÍCULAS VOLUMÉTRICAS EN POLVO DE ORO & DATOS (Master Prompt V2 - Fase 1)
  // Partículas etéreas circulares con halo suave, flotación armónica y aditividad
  // =========================================================================
  const goldDustTex = particleGlowTexture({ size: 64, color: 'rgba(255, 217, 120, 0.95)' });
  const cyanDustTex = particleGlowTexture({ size: 64, color: 'rgba(0, 240, 255, 0.92)' });

  // 1. Motes de Polvo de Oro Volumétrico (Atrio y Haces Cenitales)
  const goldCount = 220;
  const goldGeo = new THREE.BufferGeometry();
  const goldPos = new Float32Array(goldCount * 3);
  const goldPhases = new Float32Array(goldCount);

  for (let i = 0; i < goldCount; i++) {
    const rad = 0.4 + Math.random() * (HALF * 0.95);
    const theta = Math.random() * Math.PI * 2;
    goldPos[i * 3] = Math.cos(theta) * rad;
    goldPos[i * 3 + 1] = 0.3 + Math.random() * (TOTAL_H * 0.85);
    goldPos[i * 3 + 2] = Math.sin(theta) * rad;
    goldPhases[i] = Math.random() * Math.PI * 2;
  }
  goldGeo.setAttribute('position', new THREE.BufferAttribute(goldPos, 3));
  const goldMat = new THREE.PointsMaterial({
    map: goldDustTex,
    color: 0xffd978,
    size: 0.11,
    transparent: true,
    opacity: 0.82,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  const goldParticles = new THREE.Points(goldGeo, goldMat);
  root.add(goldParticles);

  // 2. Motes Cibernéticos Cian y Púrpura (Corrientes de Datos)
  const cyberCount = 110;
  const cyberGeo = new THREE.BufferGeometry();
  const cyberPos = new Float32Array(cyberCount * 3);
  const cyberPhases = new Float32Array(cyberCount);

  for (let i = 0; i < cyberCount; i++) {
    cyberPos[i * 3] = (Math.random() - 0.5) * HALF * 1.6;
    cyberPos[i * 3 + 1] = 0.2 + Math.random() * TOTAL_H * 0.9;
    cyberPos[i * 3 + 2] = (Math.random() - 0.5) * HALF * 1.6;
    cyberPhases[i] = Math.random() * Math.PI * 2;
  }
  cyberGeo.setAttribute('position', new THREE.BufferAttribute(cyberPos, 3));
  const cyberMat = new THREE.PointsMaterial({
    map: cyanDustTex,
    color: 0x00f0ff,
    size: 0.085,
    transparent: true,
    opacity: 0.72,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  const cyberParticles = new THREE.Points(cyberGeo, cyberMat);
  root.add(cyberParticles);

  // Animación suave de convección y vaivén armónico (Cero asignaciones GC para 60 FPS fijos)
  animated.push((dt, t) => {
    const gPos = goldGeo.attributes.position.array;
    for (let i = 0; i < goldCount; i++) {
      const idx = i * 3;
      // Deriva vertical ascendente suave
      gPos[idx + 1] += dt * 0.22;
      if (gPos[idx + 1] > TOTAL_H * 0.88) {
        gPos[idx + 1] = 0.25;
      }
      // Oscilación browniana armónica
      gPos[idx] += Math.sin(t * 0.8 + goldPhases[i]) * 0.0025;
      gPos[idx + 2] += Math.cos(t * 0.7 + goldPhases[i]) * 0.0025;
    }
    goldGeo.attributes.position.needsUpdate = true;

    const cPos = cyberGeo.attributes.position.array;
    for (let i = 0; i < cyberCount; i++) {
      const idx = i * 3;
      cPos[idx + 1] -= dt * 0.16;
      if (cPos[idx + 1] < 0.2) {
        cPos[idx + 1] = TOTAL_H * 0.88;
      }
      cPos[idx] += Math.cos(t * 0.6 + cyberPhases[i]) * 0.003;
    }
    cyberGeo.attributes.position.needsUpdate = true;
  });

  // =========================================================================
  // 2B. MURO CORTINA PANORÁMICO DOBLE ALTURA (Vistas al Skyline Metropolitano GTA VI)
  // =========================================================================
  const darkGraniteMat = new THREE.MeshStandardMaterial({
    color: 0x0f172a,
    roughness: 0.18,
    metalness: 0.8,
  });
  const curtainGlassMat = new THREE.MeshPhysicalMaterial({
    color: 0xffffff,
    transparent: true,
    opacity: 0.24,
    roughness: 0.04,
    metalness: 0.1,
    transmission: 0.92,
    ior: 1.52,
    envMapIntensity: 2.0,
  });
  const titaniumMat = new THREE.MeshStandardMaterial({
    color: 0x1e293b,
    roughness: 0.25,
    metalness: 0.85,
  });

  // Zócalo arquitectónico inferior en granito negro pulido
  const wallBackDado = box(HALF * 2, 0.75, 0.24, darkGraniteMat, 0, 0.375, -HALF, true, true);
  // Cristal templado continuo de doble altura (10m de altura)
  const curtainGlass = box(HALF * 2, TOTAL_H - 1.1, 0.06, curtainGlassMat, 0, (TOTAL_H + 0.75) / 2, -HALF, false, false);
  root.add(wallBackDado, curtainGlass);

  // Montantes verticales de titanio cada 2.4 metros
  for (let mx = -HALF + 1.2; mx < HALF; mx += 2.4) {
    const mullion = box(0.08, TOTAL_H, 0.14, titaniumMat, mx, TOTAL_H / 2, -HALF);
    root.add(mullion);
  }
  // Travesaño estructural horizontal a la altura del Mezzanine
  const transom = box(HALF * 2, 0.14, 0.15, titaniumMat, 0, MEZZANINE_Y, -HALF);
  root.add(transom);

  // Skyline Panorámico Metropolitano 2K visible en alta definición tras el ventanal
  const skylineMat = new THREE.MeshBasicMaterial({
    map: panoramicSkylineTexture({ w: 2048, h: 512 }),
    side: THREE.DoubleSide,
  });
  const skylineMesh = new THREE.Mesh(
    new THREE.PlaneGeometry(HALF * 2.8, TOTAL_H * 1.35),
    skylineMat,
  );
  skylineMesh.position.set(0, TOTAL_H * 0.58, -HALF - 0.45);
  root.add(skylineMesh);

  // Muros perimetrales arquitectónicos en Negro Obsidiana (#0A0A0C) satinado
  const wallMat = new THREE.MeshStandardMaterial({
    color: NEGRO_OBSIDIANA,
    roughness: 0.28,
    metalness: 0.82,
  });

  const wallFront = box(HALF * 2, TOTAL_H, 0.2, wallMat, 0, TOTAL_H / 2, HALF, true, true);
  const wallLeft = box(0.2, TOTAL_H, HALF * 2, wallMat, -HALF, TOTAL_H / 2, 0, true, true);
  const wallRight = box(0.2, TOTAL_H, HALF * 2, wallMat, HALF, TOTAL_H / 2, 0, true, true);
  root.add(wallFront, wallLeft, wallRight);

  // Revestimiento de Palillería Acústica en Negro Obsidiana y Oro
  const woodPanelMat = new THREE.MeshStandardMaterial({
    map: flutedWoodTexture({ w: 1024, h: 1024, slats: 36 }),
    roughness: 0.38,
    metalness: 0.55,
  });
  const leftWoodFeature = box(0.08, TOTAL_H * 0.72, 5.2, woodPanelMat, -HALF + 0.14, TOTAL_H * 0.36, -1.8);
  const leftWoodCove = box(0.04, TOTAL_H * 0.74, 5.3, glow(ORO_PREMIUM, 2.0), -HALF + 0.12, TOTAL_H * 0.36, -1.8, false, false);
  root.add(leftWoodFeature, leftWoodCove);

  // Líneas de luz arquitectónicas empotradas en Oro Premium WordVerse (#D4AF37 / #FFD978)
  for (const y of [0.15, MEZZANINE_Y - 0.05, MEZZANINE_Y + 0.1, TOTAL_H - 0.2]) {
    const stripB = box(HALF * 2, 0.05, 0.04, glow(ORO_PREMIUM, 2.2), 0, y, -HALF + 0.12, false, false);
    const stripL = box(0.04, 0.05, HALF * 2, glow(ORO_LUMINOSO, 2.0), -HALF + 0.12, y, 0, false, false);
    const stripR = box(0.04, 0.05, HALF * 2, glow(ORO_PREMIUM, 2.2), HALF - 0.12, y, 0, false, false);
    root.add(stripB, stripL, stripR);
  }

  // Techo artesonado arquitectónico en Negro Obsidiana con fosa de luz Oro Premium
  const ceilingMat = new THREE.MeshStandardMaterial({ color: NEGRO_OBSIDIANA, roughness: 0.5, metalness: 0.75 });
  const ceiling = box(HALF * 2, 0.3, HALF * 2, ceilingMat, 0, TOTAL_H + 0.15, 0, false, true);
  const ceilingCoveLight = box(HALF * 2 - 1.2, 0.06, HALF * 2 - 1.2, glow(ORO_PREMIUM, 2.4), 0, TOTAL_H - 0.02, 0, false, false);
  root.add(ceiling, ceilingCoveLight);

  // Cúpula central acristalada monumental con vista al cielo y rascacielos estilo GTA VI
  const domeRadius = 4.4;
  const cupolaMat = new THREE.MeshPhysicalMaterial({
    color: 0xffd978,
    transparent: true,
    opacity: 0.22,
    roughness: 0.05,
    metalness: 0.25,
    transmission: 0.9,
    ior: 1.5,
  });
  const domeMesh = new THREE.Mesh(
    new THREE.SphereGeometry(domeRadius, 32, 16, 0, Math.PI * 2, 0, Math.PI * 0.45),
    cupolaMat,
  );
  domeMesh.position.set(0, TOTAL_H, 0);
  root.add(domeMesh);

  // Nervaduras de Oro Cepillado estructural de la cúpula
  for (let i = 0; i < 8; i++) {
    const archAngle = i * (Math.PI / 4);
    const archRing = new THREE.Mesh(
      new THREE.TorusGeometry(domeRadius * 0.98, 0.05, 8, 32, Math.PI * 0.45),
      glow(ORO_PREMIUM, 2.0),
    );
    archRing.rotation.y = archAngle;
    archRing.rotation.z = Math.PI / 2;
    archRing.position.set(0, TOTAL_H, 0);
    root.add(archRing);
  }

  // =========================================================================
  // 2C. GRAN EMBLEMA CELESTIAL CONJUNTO EN EL CIELO (4 LOGOS UNIDOS PREMION)
  // =========================================================================
  const texLoader = new THREE.TextureLoader();
  const skyEmblemTex = texLoader.load('./assets/sky_emblem_united.png');
  const skyEmblemGeo = new THREE.CircleGeometry(7.6, 64);
  const skyEmblemMat = new THREE.MeshBasicMaterial({
    map: skyEmblemTex,
    transparent: true,
    side: THREE.DoubleSide,
    depthWrite: false,
  });
  const skyEmblemMesh = new THREE.Mesh(skyEmblemGeo, skyEmblemMat);
  skyEmblemMesh.rotation.x = Math.PI / 2;
  skyEmblemMesh.position.set(0, 13.8, 0);
  root.add(skyEmblemMesh);

  // Aureola y aros de constelación dorados y cian alrededor del emblema celeste
  const skyRingGold = new THREE.Mesh(new THREE.TorusGeometry(7.7, 0.09, 12, 64), glow(ORO_PREMIUM, 3.2));
  skyRingGold.rotation.x = Math.PI / 2;
  skyRingGold.position.set(0, 13.78, 0);

  const skyRingCyan = new THREE.Mesh(new THREE.TorusGeometry(8.1, 0.05, 12, 64), glow(CIAN_HOLO, 2.5));
  skyRingCyan.rotation.x = Math.PI / 2;
  skyRingCyan.position.set(0, 13.76, 0);
  root.add(skyRingGold, skyRingCyan);

  animated.push((dt, t) => {
    skyEmblemMesh.rotation.z = t * 0.04;
    skyRingGold.rotation.z = -t * 0.025;
    skyRingCyan.rotation.z = t * 0.035;
  });

  // Rascacielos iluminados en el skyline nocturno visible en el horizonte
  const towerMat = new THREE.MeshStandardMaterial({ color: 0x0b1329, roughness: 0.7, metalness: 0.6 });
  const towerWindowMat = glow(0x38bdf8, 1.5);
  const towerAmberMat = glow(0xf59e0b, 2.5);

  const towers = [
    { x: -14, z: -20, w: 6, h: 28, d: 7 },
    { x: 10, z: -22, w: 7, h: 32, d: 8 },
    { x: 0, z: -24, w: 5, h: 26, d: 5 },
    { x: -18, z: 6, w: 6, h: 26, d: 6 },
    { x: 11, z: 20, w: 7, h: 30, d: 7 },
    { x: -12, z: 18, w: 5, h: 22, d: 5 },
  ];

  for (const t of towers) {
    const tower = box(t.w, t.h, t.d, towerMat, t.x, t.h / 2, t.z, false, false);
    const beacon = box(0.3, 0.3, 0.3, towerAmberMat, t.x, t.h + 0.2, t.z, false, false);
    for (let wy = 8; wy < t.h - 2; wy += 3.5) {
      const win = box(t.w * 0.85, 0.25, t.d * 0.85, towerWindowMat, t.x, wy, t.z, false, false);
      root.add(win);
    }
    root.add(tower, beacon);
  }

  // =========================================================================
  // 3. MEZZANINE / SEGUNDO PISO (Planta Alta)
  // =========================================================================
  const concreteMat = new THREE.MeshStandardMaterial({
    map: royalMarblePbrTexture({ w: 1024, h: 1024, tileCount: 6 }),
    roughness: 0.16,
    metalness: 0.3,
    envMapIntensity: 1.4,
  });

  // Pasarela perimetral en la planta alta (con hueco central amplio para el atrio)
  const mezBack = box(HALF * 2, 0.25, 3.8, concreteMat, 0, MEZZANINE_Y, -HALF + 1.9, true, true);
  const mezLeft = box(3.6, 0.25, HALF * 2, concreteMat, -HALF + 1.8, MEZZANINE_Y, 0, true, true);
  const mezRight = box(2.6, 0.25, HALF * 2, concreteMat, HALF - 1.3, MEZZANINE_Y, 0, true, true);
  root.add(mezBack, mezLeft, mezRight);

  // Alfombra ejecutiva de lujo en el Mezzanine con ribetes dorados
  const carpetMat = new THREE.MeshStandardMaterial({
    color: 0x0a192f,
    roughness: 0.85,
    metalness: 0.15,
  });
  const goldBorderMat = glow(0xd4af37, 1.6);
  const mezCarpetBack = box(HALF * 2 - 2.0, 0.02, 1.8, carpetMat, 0, MEZZANINE_Y + 0.135, -HALF + 2.2, false, true);
  const mezCarpetBorder = box(HALF * 2 - 1.9, 0.025, 1.88, goldBorderMat, 0, MEZZANINE_Y + 0.13, -HALF + 2.2, false, false);
  root.add(mezCarpetBack, mezCarpetBorder);

  // Barandillas de vidrio de seguridad de alta gama con pasamanos en Oro WordVerse (#D4AF37)
  const glassRailMat = new THREE.MeshPhysicalMaterial({
    color: 0xffffff,
    transparent: true,
    opacity: 0.35,
    roughness: 0.06,
    metalness: 0.15,
    transmission: 0.85,
    ior: 1.52,
    envMapIntensity: 1.6,
  });
  const handrailMat = glow(ORO_PREMIUM, 2.0);

  // Barandilla del ala izquierda mirando al atrio (con apertura monumental para el ascensor panorámico)
  const railLeftNorth = box(0.06, 1.0, 4.0, glassRailMat, -4.6, MEZZANINE_Y + 0.5, -2.8, false, false);
  const handLeftNorth = box(0.1, 0.05, 4.0, handrailMat, -4.6, MEZZANINE_Y + 1.02, -2.8, false, false);
  const railLeftSouth = box(0.06, 1.0, 6.4, glassRailMat, -4.6, MEZZANINE_Y + 0.5, 4.6, false, false);
  const handLeftSouth = box(0.1, 0.05, 6.4, handrailMat, -4.6, MEZZANINE_Y + 1.02, 4.6, false, false);
  root.add(railLeftNorth, handLeftNorth, railLeftSouth, handLeftSouth);

  // Barandilla del fondo mirando al atrio con apertura despejada para las escaleras (X: 3.8 a 5.8)
  const railBackL = box(8.3, 1.0, 0.06, glassRailMat, -0.45, MEZZANINE_Y + 0.5, -4.4, false, false);
  const handBackL = box(8.3, 0.05, 0.1, handrailMat, -0.45, MEZZANINE_Y + 1.02, -4.4, false, false);
  const railBackR = box(0.9, 1.0, 0.06, glassRailMat, 6.25, MEZZANINE_Y + 0.5, -4.4, false, false);
  const handBackR = box(0.9, 0.05, 0.1, handrailMat, 6.25, MEZZANINE_Y + 1.02, -4.4, false, false);
  root.add(railBackL, handBackL, railBackR, handBackR);

  // =========================================================================
  // 3B. ESPACIO PROPIO DE LA ESCALERA MONUMENTAL DORADA WORDVERSE (ALA ESTE)
  // Ubicada en su propio atrio despejado (X = 4.8m, Z = -0.6m a -4.4m) con pórtico y plaza dorada
  // =========================================================================
  const stairSteps = 21;
  const stairZStart = -0.6; // Nivel 1 (Y = 0)
  const stairZEnd = -4.4;   // Nivel 2 (Y = 4.2)
  const stairStepRise = MEZZANINE_Y / stairSteps;
  const stairStepRun = (stairZStart - stairZEnd) / stairSteps;
  const stairWidth = 1.9;
  const stairX = 4.8;

  const stairGroup = new THREE.Group();
  stairGroup.name = 'monumental_stairs';
  root.add(stairGroup);

  const stepMat = new THREE.MeshStandardMaterial({
    map: royalMarblePbrTexture({ w: 512, h: 512, tileCount: 2 }),
    roughness: 0.14,
    metalness: 0.35,
  });
  const stepGoldMat = glow(ORO_LUMINOSO, 2.8);
  const stringerMat = goldTrimMat;

  const stairHypot = Math.hypot(stairZStart - stairZEnd, MEZZANINE_Y);
  const stairAng = Math.atan2(MEZZANINE_Y, stairZStart - stairZEnd);
  const stringerH = 0.24;

  // 1. Plaza / Espacio Propio de Recepción al Pie de la Escalera (X = 4.8, Z = 0.15)
  const stairPlazaPad = new THREE.Mesh(
    new THREE.CircleGeometry(1.45, 48),
    obsidianMat,
  );
  stairPlazaPad.rotation.x = -Math.PI / 2;
  stairPlazaPad.position.set(stairX, 0.014, stairZStart + 0.75);
  const stairPlazaRingOuter = new THREE.Mesh(
    new THREE.RingGeometry(1.42, 1.50, 48),
    glow(ORO_PREMIUM, 2.6),
  );
  stairPlazaRingOuter.rotation.x = -Math.PI / 2;
  stairPlazaRingOuter.position.set(stairX, 0.018, stairZStart + 0.75);
  const stairPlazaRingInner = new THREE.Mesh(
    new THREE.RingGeometry(1.05, 1.10, 48),
    glow(ORO_LUMINOSO, 2.2),
  );
  stairPlazaRingInner.rotation.x = -Math.PI / 2;
  stairPlazaRingInner.position.set(stairX, 0.019, stairZStart + 0.75);
  stairGroup.add(stairPlazaPad, stairPlazaRingOuter, stairPlazaRingInner);

  // Pórtico Dorado de Entrada a la Escalera Monumental
  const stairArchColL = box(0.14, 3.1, 0.14, goldTrimMat, stairX - stairWidth / 2 - 0.12, 1.55, stairZStart + 0.15);
  const stairArchColR = box(0.14, 3.1, 0.14, goldTrimMat, stairX + stairWidth / 2 + 0.12, 1.55, stairZStart + 0.15);
  const stairArchTop = box(stairWidth + 0.42, 0.14, 0.18, glow(ORO_PREMIUM, 2.4), stairX, 3.12, stairZStart + 0.15, false, false);
  const stairSpotLight = new THREE.PointLight(0xfff0c2, 22, 7.5, 1.5);
  stairSpotLight.position.set(stairX, 3.6, -1.8);
  stairGroup.add(stairArchColL, stairArchColR, stairArchTop, stairSpotLight);

  // Peldaños de mármol con filo luminoso en Oro WordVerse
  for (let i = 0; i < stairSteps; i++) {
    const sy = (i + 0.5) * stairStepRise;
    const sz = stairZStart - (i + 0.5) * stairStepRun;
    const step = box(stairWidth, stairStepRise * 0.95, stairStepRun * 1.15, stepMat, stairX, sy, sz, true, true);
    const neonGold = box(stairWidth * 0.96, 0.038, 0.045, stepGoldMat, stairX, sy + stairStepRise * 0.45, sz + stairStepRun * 0.55, false, false);
    stairGroup.add(step, neonGold);
  }

  // Zancas laterales en Oro Cepillado WordVerse
  const stringerL = box(0.10, stringerH, stairHypot, stringerMat, stairX - stairWidth / 2 - 0.05, MEZZANINE_Y / 2, (stairZStart + stairZEnd) / 2);
  stringerL.rotation.x = stairAng;
  const stringerR = box(0.10, stringerH, stairHypot, stringerMat, stairX + stairWidth / 2 + 0.05, MEZZANINE_Y / 2, (stairZStart + stairZEnd) / 2);
  stringerR.rotation.x = stairAng;
  stairGroup.add(stringerL, stringerR);

  // Barandillas de cristal en ambos lados con pasamanos en Oro Luminoso WordVerse
  for (const side of [-1, 1]) {
    const railX = stairX + side * (stairWidth / 2 + 0.05);
    const railGoldStrip = box(0.05, 0.05, stairHypot, glow(ORO_PREMIUM, 2.5), railX, MEZZANINE_Y / 2 + 0.1, (stairZStart + stairZEnd) / 2, false, false);
    railGoldStrip.rotation.x = stairAng;
    const stairRail = box(0.05, 0.88, stairHypot, glassRailMat, railX, MEZZANINE_Y / 2 + 0.45, (stairZStart + stairZEnd) / 2, false, false);
    stairRail.rotation.x = stairAng;
    const stairHand = box(0.09, 0.06, stairHypot, glow(ORO_LUMINOSO, 2.4), railX, MEZZANINE_Y / 2 + 0.92, (stairZStart + stairZEnd) / 2, false, false);
    stairHand.rotation.x = stairAng;
    stairGroup.add(railGoldStrip, stairRail, stairHand);
  }

  // Letrero Dorado sobre el pórtico de la escalera
  const stairSign = new THREE.Mesh(
    new THREE.PlaneGeometry(2.1, 0.48),
    new THREE.MeshBasicMaterial({
      map: signTexture('⬆ ESCALERA IMPERIAL · MEZZANINE', { w: 640, h: 148, font: 36, color: '#ffd978' }),
      transparent: true,
    }),
  );
  stairSign.position.set(stairX, 3.45, stairZStart + 0.22);
  stairGroup.add(stairSign);

  // Lámparas Circulares Suspendidas en Mezzanine (Chandeliers en Oro WordVerse)
  for (const [lx, lCol] of [[-4.8, ORO_LUMINOSO], [4.8, ORO_PREMIUM]]) {
    const ringChandelier = new THREE.Group();
    ringChandelier.position.set(lx, 7.8, -1.8);

    const outerGold = new THREE.Mesh(new THREE.TorusGeometry(1.5, 0.05, 8, 48), glow(ORO_PREMIUM, 2.4));
    outerGold.rotation.x = Math.PI / 2;
    const innerHalo = new THREE.Mesh(new THREE.TorusGeometry(1.1, 0.04, 8, 48), glow(lCol, 2.4));
    innerHalo.rotation.x = Math.PI / 2;
    ringChandelier.add(outerGold, innerHalo);

    for (let c = 0; c < 3; c++) {
      const cAng = c * (Math.PI * 2 / 3);
      const cable = box(0.015, 2.8, 0.015, goldTrimMat, Math.cos(cAng) * 1.4, 1.4, Math.sin(cAng) * 1.4);
      ringChandelier.add(cable);
    }
    root.add(ringChandelier);
  }

  // =========================================================================
  // 3C. ESPACIO PROPIO DEL ASCENSOR PANORÁMICO DE CRISTAL Y ORO (ALA OESTE)
  // Bahía exclusiva despejada en el Ala Oeste (X = -6.2m, Z = 0.0m) con pórtico, plaza y luz dorada
  // =========================================================================
  const elevGroup = new THREE.Group();
  elevGroup.name = 'panoramic_glass_elevator';
  root.add(elevGroup);

  const elevCX = ELEVATOR.x * S; // -6.2m
  const elevCZ = ELEVATOR.z * S; // 0.0m
  const elevW = 2.2;
  const elevD = 2.2;
  const elevH = 9.8;

  // Pasarela voladiza de cristal en Mezzanine (Piso 2) conectando elevCX (-6.2m) con la pasarela oeste (-4.6m)
  const bridgeW = 2.4;
  const bridgeCX = (elevCX + (-4.6)) / 2; // -5.4m
  const elevUpperLanding = box(bridgeW, 0.25, 2.2, concreteMat, bridgeCX, MEZZANINE_Y, elevCZ + elevD / 2 + 0.1, true, true);
  const landRailL = box(bridgeW, 1.0, 0.06, glassRailMat, bridgeCX, MEZZANINE_Y + 0.5, elevCZ + elevD / 2 - 0.95, false, false);
  const landHandL = box(bridgeW, 0.05, 0.08, handrailMat, bridgeCX, MEZZANINE_Y + 1.02, elevCZ + elevD / 2 - 0.95, false, false);
  const landRailR = box(bridgeW, 1.0, 0.06, glassRailMat, bridgeCX, MEZZANINE_Y + 0.5, elevCZ + elevD / 2 + 1.15, false, false);
  const landHandR = box(bridgeW, 0.05, 0.08, handrailMat, bridgeCX, MEZZANINE_Y + 1.02, elevCZ + elevD / 2 + 1.15, false, false);
  elevGroup.add(elevUpperLanding, landRailL, landHandL, landRailR, landHandR);

  // Vestíbulo / Plaza Exclusiva del Ascensor en Planta Baja (Espacio Propio en Oro WordVerse)
  const elevFoyerPad = box(3.4, 0.02, 3.8, obsidianMat, elevCX, 0.012, elevCZ + 0.7, false, true);
  const elevFoyerGoldBorder = box(3.52, 0.024, 3.92, glow(ORO_PREMIUM, 2.6), elevCX, 0.010, elevCZ + 0.7, false, false);
  const elevFoyerRing = new THREE.Mesh(
    new THREE.RingGeometry(1.25, 1.33, 48),
    glow(ORO_LUMINOSO, 2.5),
  );
  elevFoyerRing.rotation.x = -Math.PI / 2;
  elevFoyerRing.position.set(elevCX, 0.022, elevCZ + elevD / 2 + 0.95);
  // Pórtico Dorado de Bienvenida al Vestíbulo del Ascensor
  const elevFoyerColL = box(0.14, 3.3, 0.14, goldTrimMat, elevCX - 1.45, 1.65, elevCZ + elevD / 2 + 1.4);
  const elevFoyerColR = box(0.14, 3.3, 0.14, goldTrimMat, elevCX + 1.45, 1.65, elevCZ + elevD / 2 + 1.4);
  const elevFoyerArch = box(3.08, 0.14, 0.18, glow(ORO_PREMIUM, 2.5), elevCX, 3.32, elevCZ + elevD / 2 + 1.4, false, false);
  const elevFoyerLight = new THREE.PointLight(0xfff0c2, 28, 8.5, 1.4);
  elevFoyerLight.position.set(elevCX, 3.8, elevCZ + 1.2);
  elevGroup.add(elevFoyerPad, elevFoyerGoldBorder, elevFoyerRing, elevFoyerColL, elevFoyerColR, elevFoyerArch, elevFoyerLight);

  // 1. Columnas estructurales en Oro Premium y Negro Obsidiana
  const colMat = new THREE.MeshStandardMaterial({
    color: ORO_PREMIUM,
    metalness: 0.94,
    roughness: 0.16,
    envMapIntensity: 2.0,
  });
  const colGeo = new THREE.CylinderGeometry(0.075, 0.075, elevH, 16);
  for (const [dx, dz] of [[-elevW / 2, -elevD / 2], [elevW / 2, -elevD / 2], [-elevW / 2, elevD / 2], [elevW / 2, elevD / 2]]) {
    const col = new THREE.Mesh(colGeo, colMat);
    col.position.set(elevCX + dx, elevH / 2, elevCZ + dz);
    col.castShadow = true;
    elevGroup.add(col);
  }

  // 2. Anillos estructurales en Oro Luminoso WordVerse en cada nivel (base, mezzanine, techo)
  for (const fy of [0.08, MEZZANINE_Y, elevH - 0.1]) {
    const ringF = box(elevW + 0.14, 0.12, elevD + 0.14, glow(ORO_LUMINOSO, 2.4), elevCX, fy, elevCZ, false, false);
    const ringGold = box(elevW + 0.18, 0.05, elevD + 0.18, goldTrimMat, elevCX, fy + 0.08, elevCZ, false, false);
    elevGroup.add(ringF, ringGold);
  }

  // 3. Vidrios panorámicos ultratransparentes del fuste (lados y fondo)
  const shaftGlassMat = new THREE.MeshPhysicalMaterial({
    color: 0xffffff,
    transparent: true,
    opacity: 0.35,
    roughness: 0.04,
    metalness: 0.1,
    transmission: 0.88,
    ior: 1.52,
  });
  const glassBack = box(elevW - 0.1, elevH, 0.06, shaftGlassMat, elevCX, elevH / 2, elevCZ - elevD / 2);
  const glassLeft = box(0.06, elevH, elevD - 0.1, shaftGlassMat, elevCX - elevW / 2, elevH / 2, elevCZ);
  const glassRight = box(0.06, elevH, elevD - 0.1, shaftGlassMat, elevCX + elevW / 2, elevH / 2, elevCZ);
  elevGroup.add(glassBack, glassLeft, glassRight);

  // Pistón hidráulico central cromado visible (GTA V Luxury)
  const pistonMat = new THREE.MeshStandardMaterial({ color: 0xffffff, metalness: 0.98, roughness: 0.08 });
  const pistonCyl = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.12, elevH, 24), pistonMat);
  pistonCyl.position.set(elevCX, elevH / 2, elevCZ - 0.5);
  elevGroup.add(pistonCyl);

  // 4. Puertas de Piso corredizas
  const doorMat = new THREE.MeshStandardMaterial({
    color: 0x38bdf8,
    roughness: 0.15,
    metalness: 0.85,
    transparent: true,
    opacity: 0.72,
  });
  const floor1DoorL = box(0.68, 2.4, 0.05, doorMat, elevCX - 0.36, 1.2, elevCZ + elevD / 2);
  const floor1DoorR = box(0.68, 2.4, 0.05, doorMat, elevCX + 0.36, 1.2, elevCZ + elevD / 2);
  elevGroup.add(floor1DoorL, floor1DoorR);

  const floor2DoorL = box(0.68, 2.4, 0.05, doorMat, elevCX - 0.36, MEZZANINE_Y + 1.2, elevCZ + elevD / 2);
  const floor2DoorR = box(0.68, 2.4, 0.05, doorMat, elevCX + 0.36, MEZZANINE_Y + 1.2, elevCZ + elevD / 2);
  elevGroup.add(floor2DoorL, floor2DoorR);

  // Letreros luminosos sobre cada puerta
  const elevSign1 = new THREE.Mesh(
    new THREE.PlaneGeometry(2.0, 0.5),
    new THREE.MeshBasicMaterial({
      map: signTexture('WORDVERSE ELEVATOR · P1 ATRIO', { w: 512, h: 140, font: 38 }),
      transparent: true,
    }),
  );
  elevSign1.position.set(elevCX, 2.65, elevCZ + elevD / 2 + 0.06);
  const elevSign2 = new THREE.Mesh(
    new THREE.PlaneGeometry(2.0, 0.5),
    new THREE.MeshBasicMaterial({
      map: signTexture('WORDVERSE ELEVATOR · P2 MEZZANINE', { w: 512, h: 140, font: 38 }),
      transparent: true,
    }),
  );
  elevSign2.position.set(elevCX, MEZZANINE_Y + 2.65, elevCZ + elevD / 2 + 0.06);
  elevGroup.add(elevSign1, elevSign2);

  // 5. Cabina móvil de cristal
  const cabGroup = new THREE.Group();
  cabGroup.name = 'elevator_cab';
  elevGroup.add(cabGroup);

  const cabFloor = box(elevW - 0.2, 0.12, elevD - 0.2, new THREE.MeshStandardMaterial({ color: NEGRO_OBSIDIANA, roughness: 0.2, metalness: 0.8 }), elevCX, 0.06, elevCZ);
  const cabFloorGlow = box(elevW - 0.15, 0.04, elevD - 0.15, glow(ORO_PREMIUM, 2.4), elevCX, 0.08, elevCZ, false, false);
  const cabCeil = box(elevW - 0.2, 0.12, elevD - 0.2, goldTrimMat, elevCX, 2.65, elevCZ);
  const cabLight = new THREE.PointLight(0xfff5e6, 35, 4.5, 1.2);
  cabLight.position.set(elevCX, 2.45, elevCZ);

  const cabGlassBack = box(elevW - 0.25, 2.4, 0.04, shaftGlassMat, elevCX, 1.3, elevCZ - elevD / 2 + 0.12);
  const cabGlassLeft = box(0.04, 2.4, elevD - 0.25, shaftGlassMat, elevCX - elevW / 2 + 0.12, 1.3, elevCZ);
  const cabGlassRight = box(0.04, 2.4, elevD - 0.25, shaftGlassMat, elevCX + elevW / 2 - 0.12, 1.3, elevCZ);

  // Puertas corredizas de la cabina
  const cabDoorL = box(0.64, 2.38, 0.04, shaftGlassMat, elevCX - 0.34, 1.3, elevCZ + elevD / 2 - 0.08);
  const cabDoorR = box(0.64, 2.38, 0.04, shaftGlassMat, elevCX + 0.34, 1.3, elevCZ + elevD / 2 - 0.08);
  const cabPanel = box(0.24, 0.60, 0.04, glow(CIAN_HOLO, 2.5), elevCX + elevW / 2 - 0.15, 1.3, elevCZ + 0.2, false, false);

  // Display digital con flecha holográfica que indica el estado del piso
  const arrowTex = canvasTexture(256, 256, (ctx, w, h) => {
    ctx.fillStyle = '#0a0a0c';
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = '#d4af37';
    ctx.lineWidth = 4;
    ctx.strokeRect(2, 2, w - 4, h - 4);
    ctx.fillStyle = '#00f0ff';
    ctx.beginPath();
    ctx.moveTo(w / 2, 35);
    ctx.lineTo(w - 45, h - 65);
    ctx.lineTo(45, h - 65);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 32px "Segoe UI", sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('ELEVATOR', w / 2, h - 18);
  });
  const cabDisplay = new THREE.Mesh(
    new THREE.PlaneGeometry(0.38, 0.38),
    new THREE.MeshBasicMaterial({ map: arrowTex, transparent: true, toneMapped: false }),
  );
  cabDisplay.position.set(elevCX, 2.2, elevCZ + elevD / 2 - 0.12);
  cabGroup.add(cabFloor, cabFloorGlow, cabCeil, cabLight, cabGlassBack, cabGlassLeft, cabGlassRight, cabDoorL, cabDoorR, cabPanel, cabDisplay);

  // 6. Corona Monumental con Baliza Holográfica 3D (Visible 360° desde cualquier punto)
  const crownGroup = new THREE.Group();
  crownGroup.position.set(elevCX, elevH + 0.45, elevCZ);
  elevGroup.add(crownGroup);

  const crownBase = box(elevW + 0.3, 0.3, elevD + 0.3, goldTrimMat, 0, 0, 0);
  const crownTrim = box(elevW + 0.4, 0.1, elevD + 0.4, obsidianMat, 0, 0.2, 0);
  crownGroup.add(crownBase, crownTrim);

  // Rótulo holográfico giratorio de 4 caras con el nombre oficial
  const beaconTex = canvasTexture(512, 128, (ctx, w, h) => {
    ctx.fillStyle = '#0a0a0c';
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = '#d4af37';
    ctx.lineWidth = 4;
    ctx.strokeRect(2, 2, w - 4, h - 4);
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillStyle = '#00f0ff';
    ctx.font = '900 32px "Segoe UI", sans-serif';
    ctx.fillText('🛗 WORDVERSE ELEVATOR', w / 2, 45);
    ctx.fillStyle = '#d4af37';
    ctx.font = '700 20px "Segoe UI", sans-serif';
    ctx.fillText('VIP PANORAMIC ACCESS', w / 2, 88);
  });
  const beaconMat = new THREE.MeshBasicMaterial({ map: beaconTex, transparent: true, side: THREE.DoubleSide });

  for (let bi = 0; bi < 4; bi++) {
    const bMesh = new THREE.Mesh(new THREE.PlaneGeometry(1.9, 0.55), beaconMat);
    const bAng = bi * (Math.PI / 2);
    bMesh.position.set(Math.sin(bAng) * (elevW / 2 + 0.12), 0.72, Math.cos(bAng) * (elevD / 2 + 0.12));
    bMesh.rotation.y = bAng;
    crownGroup.add(bMesh);
  }

  // Haz vertical volumétrico de luz hacia el techo
  const elevLightBeam = new THREE.Mesh(new THREE.CylinderGeometry(0.16, 0.35, 3.2, 16), glow(CIAN_HOLO, 3.2));
  elevLightBeam.position.set(0, 2.2, 0);
  crownGroup.add(elevLightBeam);

  const beaconOrb = new THREE.Mesh(new THREE.SphereGeometry(0.25, 16, 16), glow(ORO_PREMIUM, 3.5));
  beaconOrb.position.set(0, 3.8, 0);
  crownGroup.add(beaconOrb);

  animated.push((dt, t) => {
    crownGroup.rotation.y = t * 0.4;
    beaconOrb.scale.setScalar(1.0 + Math.sin(t * 3.5) * 0.15);
  });

  // Columna de partículas de luz dorada a lo largo de la columna del ascensor
  const shaftMoteCount = 42;
  const shaftGeo = new THREE.BufferGeometry();
  const shaftPos = new Float32Array(shaftMoteCount * 3);
  for (let i = 0; i < shaftMoteCount; i++) {
    shaftPos[i * 3] = (Math.random() - 0.5) * (elevW * 0.7);
    shaftPos[i * 3 + 1] = Math.random() * elevH;
    shaftPos[i * 3 + 2] = (Math.random() - 0.5) * (elevD * 0.7);
  }
  shaftGeo.setAttribute('position', new THREE.BufferAttribute(shaftPos, 3));
  const shaftMat = new THREE.PointsMaterial({
    map: goldDustTex,
    color: 0xffd978,
    size: 0.085,
    transparent: true,
    opacity: 0.82,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  const shaftParticles = new THREE.Points(shaftGeo, shaftMat);
  shaftParticles.position.set(elevCX, 0, elevCZ);
  elevGroup.add(shaftParticles);

  animated.push((dt, t) => {
    const sPos = shaftGeo.attributes.position.array;
    for (let i = 0; i < shaftMoteCount; i++) {
      sPos[i * 3 + 1] += dt * 0.42;
      if (sPos[i * 3 + 1] > elevH) sPos[i * 3 + 1] = 0.2;
    }
    shaftGeo.attributes.position.needsUpdate = true;
  });

  // Controlador de animación y cinemática del ascensor
  const elevator = {
    floor: 1, // 1 | 2
    targetFloor: 1,
    y: 0,
    targetY: 0,
    state: 'idle', // 'idle' | 'closing' | 'moving' | 'opening'
    doorProgress: 1.0, // 1 = abierta, 0 = cerrada
    travelTimer: 0,
    travelDuration: 2.5, // 2.5 segundos de viaje cinemático suave
    holdTimer: 0, // Tiempo de cortesía con puertas abiertas al llegar
    holdDuration: 4.2, // 4.2 segundos de puertas abiertas para salir con calma
    hasExitedCab: true, // Debe salir antes de activar otro viaje automático
    startY: 0,

    startTrip(targetFloorNumber) {
      if (this.state === 'moving' || this.state === 'closing') return;
      this.targetFloor = targetFloorNumber;
      this.targetY = targetFloorNumber === 2 ? MEZZANINE_Y : 0;
      this.startY = this.y;
      this.state = 'closing';
      this.holdTimer = 0;
      cabFloorGlow.material.color.setHex(0xf59e0b); // Color ámbar en tránsito
      playDoorServo();
    },

    call(floorNumber) {
      if (this.state === 'moving') return;
      if (this.floor === floorNumber && this.state === 'idle') {
        this.open();
        return;
      }
      this.startTrip(floorNumber);
    },

    toggle() {
      const next = this.floor === 1 ? 2 : 1;
      this.startTrip(next);
    },

    open() {
      if (this.doorProgress < 1 && this.state !== 'moving') {
        this.state = 'opening';
        playDoorServo();
      }
    },

    isNear(x, z, playerY) {
      const dist = Math.hypot(x - elevCX, z - (elevCZ + elevD / 2 + 0.4));
      const floorY = this.floor === 2 ? MEZZANINE_Y : 0;
      return dist <= 2.8 && Math.abs(playerY - floorY) < 1.8;
    },

    isInside(x, z) {
      return Math.abs(x - elevCX) <= (elevW / 2 - 0.05) && Math.abs(z - elevCZ) <= (elevD / 2 - 0.05);
    },

    update(dt) {
      if (this.holdTimer > 0) {
        this.holdTimer -= dt;
      }

      if (this.state === 'closing') {
        this.doorProgress = Math.max(0, this.doorProgress - dt * 2.5);
        if (this.doorProgress <= 0) {
          this.state = 'moving';
          this.travelTimer = 0;
        }
      } else if (this.state === 'opening') {
        this.doorProgress = Math.min(1, this.doorProgress + dt * 2.5);
        if (this.doorProgress >= 1) {
          this.state = 'idle';
          this.holdTimer = this.holdDuration; // Iniciar 4.2 segundos de cortesía
        }
      } else if (this.state === 'moving') {
        this.travelTimer += dt;
        const p = Math.min(1, this.travelTimer / this.travelDuration);
        const ease = 0.5 - 0.5 * Math.cos(p * Math.PI);
        this.y = this.startY + (this.targetY - this.startY) * ease;
        cabGroup.position.y = this.y;

        if (p >= 1) {
          this.y = this.targetY;
          cabGroup.position.y = this.y;
          this.floor = this.targetFloor;
          this.hasExitedCab = false; // Acaba de llegar: debe salir
          this.state = 'opening';
          cabFloorGlow.material.color.setHex(this.floor === 2 ? 0x10b981 : 0x22d3ee);
          playElevatorChime();
          playDoorServo();
        }
      }

      // Animación de puertas corredizas
      const openOffset = this.doorProgress * 0.55;
      cabDoorL.position.x = elevCX - 0.34 - openOffset;
      cabDoorR.position.x = elevCX + 0.34 + openOffset;

      if (this.floor === 1 || this.state === 'moving') {
        floor1DoorL.position.x = elevCX - 0.36 - (this.floor === 1 ? openOffset : 0);
        floor1DoorR.position.x = elevCX + 0.36 + (this.floor === 1 ? openOffset : 0);
      }
      if (this.floor === 2 || this.state === 'moving') {
        floor2DoorL.position.x = elevCX - 0.36 - (this.floor === 2 ? openOffset : 0);
        floor2DoorR.position.x = elevCX + 0.36 + (this.floor === 2 ? openOffset : 0);
      }
    },
  };

  // =========================================================================
  // 3D. VIP LOUNGE EJECUTIVO EN EL MEZZANINE (Mobiliario de Lujo GTA VI)
  // =========================================================================
  const couchMat = new THREE.MeshStandardMaterial({
    map: quiltedLeatherTexture({ w: 1024, h: 1024, count: 6 }),
    roughness: 0.42,
    metalness: 0.18,
    envMapIntensity: 1.25,
  });
  const chromeMat = new THREE.MeshStandardMaterial({
    color: 0xffffff,
    metalness: 0.95,
    roughness: 0.1,
  });

  // 2 Sets de descanso VIP en las esquinas de la pasarela alta
  for (const [lx, lz, ang, sId] of [[6.4, -6.2, 0, 'mezz_couch_1'], [6.4, 2.2, Math.PI, 'mezz_couch_2']]) {
    const couchGroup = new THREE.Group();
    couchGroup.position.set(lx, MEZZANINE_Y, lz);
    couchGroup.rotation.y = ang;

    const couchBase = box(1.8, 0.35, 0.85, couchMat, 0, 0.2, 0);
    const couchBack = box(1.8, 0.55, 0.22, couchMat, 0, 0.5, -0.32);
    couchBase.userData.seatId = sId;
    couchBack.userData.seatId = sId;
    couchGroup.add(couchBase, couchBack);
    interactables.push(couchBase, couchBack);

    const coffeeGlass = box(1.1, 0.05, 0.6, glassRailMat, 0, 0.28, 0.75);
    const coffeeBase = box(0.9, 0.24, 0.45, chromeMat, 0, 0.14, 0.75);
    couchGroup.add(coffeeGlass, coffeeBase);

    const pot = box(0.45, 0.65, 0.45, new THREE.MeshStandardMaterial({ color: 0x0f172a, roughness: 0.3 }), 1.2, 0.35, 0);
    const plant = new THREE.Mesh(new THREE.DodecahedronGeometry(0.32), glow(0x22c55e, 1.2));
    plant.position.set(1.2, 0.85, 0);
    couchGroup.add(pot, plant);

    root.add(couchGroup);
  }

  // =========================================================================
  // 4. SALAS DE REUNIONES DÚPLEX (Planta Alta: Pública / Planta Baja: Privada)
  // =========================================================================
  // --- SALA PÚBLICA (PLANTA ALTA, ALA IZQUIERDA) ---
  const publicW = 4.2;
  const publicD = 4.8;
  const publicCX = -HALF + 2.1;
  const publicCZ = 0.5;

  // Letrero exterior sobre la sala pública
  const publicSign = new THREE.Mesh(
    new THREE.PlaneGeometry(3.6, 0.7),
    new THREE.MeshBasicMaterial({
      map: signTexture('Sala de Reuniones Pública', { font: 68 }),
      transparent: true,
    }),
  );
  publicSign.position.set(publicCX + 2.15, MEZZANINE_Y + 3.8, publicCZ);
  publicSign.rotation.y = Math.PI / 2;
  root.add(publicSign);

  // Gran ventanal de vidrio templado transparente
  const publicGlass = box(0.08, 3.2, publicD - 0.2, glassRailMat, publicCX + 2.1, MEZZANINE_Y + 1.6, publicCZ, false, false);
  root.add(publicGlass);

  // Marco elegante
  const frameP1 = box(0.12, 3.2, 0.1, glow(0x94a3b8, 1.0), publicCX + 2.1, MEZZANINE_Y + 1.6, publicCZ - publicD / 2 + 0.1);
  const frameP2 = box(0.12, 3.2, 0.1, glow(0x94a3b8, 1.0), publicCX + 2.1, MEZZANINE_Y + 1.6, publicCZ + publicD / 2 - 0.1);
  const framePT = box(0.12, 0.1, publicD, glow(CYAN, 1.6), publicCX + 2.1, MEZZANINE_Y + 3.2, publicCZ);
  root.add(frameP1, frameP2, framePT);

  // Mesa de conferencias ejecutiva adentro
  // =========================================================================
  // 4A. 4 PILARES MONUMENTALES CON LOGOS EN LAS 4 ESQUINAS (IMÁGENES OFICIALES PREMION)
  // =========================================================================
  const cornerPillarsData = [
    {
      brand: 'cyber_wolf',
      title: 'CYBER WOLF',
      subtitle: 'P2P PROTOCOL',
      imagePath: './assets/logo_cyber_wolf.jpg',
      colorHex: ORO_PREMIUM,
      x: -8.2,
      z: -8.2, // Noroeste
    },
    {
      brand: 'aurum_shex',
      title: 'AURUM HEX',
      subtitle: 'SHEX MMXXIV',
      imagePath: './assets/logo_aurum_shex.jpg',
      colorHex: ORO_PREMIUM,
      x: 8.2,
      z: -8.2, // Noreste
    },
    {
      brand: 'bitcoffee',
      title: 'BITCOFFEE',
      subtitle: 'PREMIUM ROAST & TRADE',
      imagePath: './assets/logo_b_coffee.jpg',
      colorHex: ORO_PREMIUM,
      x: -8.2,
      z: 8.2, // Suroeste
    },
    {
      brand: 'wordverse_vr',
      title: 'WORDVERSE VR',
      subtitle: 'METAVERSE ECOSYSTEM',
      imagePath: './assets/logo_wordverse_vr.jpg',
      colorHex: ORO_LUMINOSO,
      x: 8.2,
      z: 8.2, // Sureste
    },
  ];

  const pillarGroup = new THREE.Group();
  pillarGroup.name = 'corner_logo_pillars';
  root.add(pillarGroup);

  for (const p of cornerPillarsData) {
    const pX = p.x;
    const pZ = p.z;
    const pColor = p.colorHex;

    // Base escalonada en Negro Obsidiana y Oro
    const pBase1 = box(1.9, 0.25, 1.9, goldTrimMat, pX, 0.125, pZ);
    const pBase2 = box(1.6, 0.45, 1.6, obsidianMat, pX, 0.45, pZ);
    pillarGroup.add(pBase1, pBase2);

    // Fuste monumental de 9.5m de altura
    const pCol = box(1.3, TOTAL_H - 1.2, 1.3, obsidianMat, pX, TOTAL_H / 2, pZ);
    const pCap = box(1.55, 0.35, 1.55, goldTrimMat, pX, TOTAL_H - 0.4, pZ);
    pillarGroup.add(pCol, pCap);

    // Ranuras verticales luminosas de neón en las 4 aristas (resplandor fino y elegante)
    for (const [ox, oz] of [[-0.66, -0.66], [0.66, -0.66], [-0.66, 0.66], [0.66, 0.66]]) {
      const neonStrip = box(0.045, TOTAL_H - 1.4, 0.045, glow(pColor, 0.95), pX + ox, TOTAL_H / 2, pZ + oz, false, false);
      pillarGroup.add(neonStrip);
    }

    // Orientación hacia el centro de la plaza
    const faceAngle = Math.atan2(-pX, -pZ);
    const panelGroup = new THREE.Group();
    panelGroup.position.set(pX + Math.sin(faceAngle) * 0.68, 2.7, pZ + Math.cos(faceAngle) * 0.68);
    panelGroup.rotation.y = faceAngle;
    pillarGroup.add(panelGroup);

    // Marco biselado de Oro y respaldo Obsidiana
    const frameMesh = box(1.75, 2.35, 0.08, goldTrimMat, 0, 0, 0);
    const backMesh = box(1.68, 2.28, 0.09, obsidianMat, 0, 0, 0.01);
    panelGroup.add(frameMesh, backMesh);

    // Imagen Real Oficial del Logo (Cargada desde assets)
    const logoTex = texLoader.load(p.imagePath);
    const logoMesh = new THREE.Mesh(
      new THREE.PlaneGeometry(1.5, 1.5),
      new THREE.MeshBasicMaterial({ map: logoTex, side: THREE.DoubleSide })
    );
    logoMesh.position.set(0, 0.32, 0.065);
    panelGroup.add(logoMesh);

    // Rótulo inferior iluminado con el nombre de la marca
    const labelTex = canvasTexture(512, 160, (ctx, w, h) => {
      ctx.fillStyle = '#0a0a0c';
      ctx.fillRect(0, 0, w, h);
      ctx.strokeStyle = '#d4af37';
      ctx.lineWidth = 6;
      ctx.strokeRect(4, 4, w - 8, h - 8);
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillStyle = '#ffffff';
      ctx.font = '900 40px "Segoe UI", sans-serif';
      ctx.fillText(p.title, w / 2, 55);
      ctx.fillStyle = '#' + new THREE.Color(pColor).getHexString();
      ctx.font = '700 24px "Segoe UI", sans-serif';
      ctx.fillText(p.subtitle, w / 2, 108);
    });
    const labelMesh = new THREE.Mesh(
      new THREE.PlaneGeometry(1.5, 0.52),
      new THREE.MeshBasicMaterial({ map: labelTex, side: THREE.DoubleSide })
    );
    labelMesh.position.set(0, -0.74, 0.065);
    panelGroup.add(labelMesh);

    // Foco de iluminación superior cenital proyectado sobre la imagen
    const spotLamp = box(0.3, 0.08, 0.25, goldTrimMat, 0, 1.25, 0.16);
    const spotGlow = box(0.24, 0.02, 0.18, glow(0xffffff, 3.0), 0, 1.21, 0.16, false, false);
    panelGroup.add(spotLamp, spotGlow);

    // Emblema 3D holográfico flotante en la cima del pilar (animado)
    const holoCrown = new THREE.Group();
    holoCrown.position.set(pX, TOTAL_H + 0.6, pZ);
    const crownRing = new THREE.Mesh(new THREE.TorusGeometry(0.7, 0.045, 8, 32), glow(pColor, 2.5));
    crownRing.rotation.x = Math.PI / 2;
    const emblemCore = new THREE.Mesh(new THREE.OctahedronGeometry(0.44), glow(pColor, 3.0));
    holoCrown.add(crownRing, emblemCore);
    pillarGroup.add(holoCrown);

    animated.push((dt, t) => {
      holoCrown.rotation.y = t * 0.6;
      holoCrown.position.y = TOTAL_H + 0.6 + Math.sin(t * 1.8) * 0.12;
    });
  }

  // =========================================================================
  // 4B. AROS CONCÉNTRICOS LUMINOSOS EN EL SUELO DEL LOBBY EN ORO WORDVERSE
  // =========================================================================
  const lobbyRings = [
    { r: 2.7, color: ORO_LUMINOSO, w: 0.05 },
    { r: 4.4, color: ORO_PREMIUM, w: 0.06 },
    { r: 6.2, color: ORO_PREMIUM, w: 0.07 },
  ];
  for (const lr of lobbyRings) {
    const rMesh = new THREE.Mesh(
      new THREE.RingGeometry(lr.r - lr.w / 2, lr.r + lr.w / 2, 64),
      glow(lr.color, 2.4),
    );
    rMesh.rotation.x = -Math.PI / 2;
    rMesh.position.set(0, 0.02, 0);
    root.add(rMesh);
  }

  // Líneas radiales conectoras en Oro WordVerse en el suelo
  for (let i = 0; i < 4; i++) {
    const radAng = i * (Math.PI / 2) + Math.PI / 4;
    const radMesh = box(0.04, 0.005, 3.6, glow(ORO_PREMIUM, 2.0), Math.cos(radAng) * 4.4, 0.022, Math.sin(radAng) * 4.4, false, false);
    radMesh.rotation.y = -radAng;
    root.add(radMesh);
  }

  // =========================================================================
  // 4C. PORTAL MONUMENTAL DE ACCESO A LA SALA PRIVADA VIP
  // Ubicado en planta baja (altura total <= 3.84m, íntegramente bajo la losa del Mezzanine y = 3.99m)
  // =========================================================================
  const privPortalGroup = new THREE.Group();
  privPortalGroup.position.set(6.2, 0, -HALF + 0.35);
  root.add(privPortalGroup);

  const privArchL = box(0.18, 3.10, 0.18, goldTrimMat, -1.5, 1.55, 0);
  const privArchR = box(0.18, 3.10, 0.18, goldTrimMat, 1.5, 1.55, 0);
  const privArchT = box(3.2, 0.16, 0.20, glow(ORO_PREMIUM, 2.5), 0, 3.10, 0, false, false);
  const privSignMesh = new THREE.Mesh(
    new THREE.PlaneGeometry(2.6, 0.64),
    new THREE.MeshBasicMaterial({
      map: premionPortalSignTexture({ title: 'SALA PRIVADA VIP', color: '#d4af37' }),
      transparent: true,
    }),
  );
  privSignMesh.position.set(0, 3.52, 0.05);

  // Velo translúcido interactivo de entrada a la Sala Privada VIP
  const privPortalVeil = new THREE.Mesh(
    new THREE.PlaneGeometry(2.8, 2.98),
    new THREE.MeshBasicMaterial({
      color: ORO_PREMIUM,
      transparent: true,
      opacity: 0.14,
      side: THREE.DoubleSide,
      depthWrite: false,
    }),
  );
  privPortalVeil.position.set(0, 1.50, 0.04);
  for (const pm of [privArchL, privArchR, privArchT, privSignMesh, privPortalVeil]) {
    pm.userData.isPrivatePortal = true;
    interactables.push(pm);
  }

  // Líneas geométricas doradas en el marco del portal privado
  for (let z = 0; z < 3; z++) {
    const geoStrip = box(2.8, 0.04, 0.04, glow(ORO_LUMINOSO, 2.2), 0, 0.95 + z * 0.75, -z * 0.32, false, false);
    privPortalGroup.add(geoStrip);
  }
  privPortalGroup.add(privArchL, privArchR, privArchT, privSignMesh, privPortalVeil);

  // Sillones curvos ejecutivos en Negro Obsidiana y Oro con jardineras bio-esmeralda en el Lobby (despejando el vestíbulo del ascensor)
  for (const [sx, sz, sAng, sId] of [[-4.6, 4.4, Math.PI * 0.25, 'sofa_left_1'], [4.6, 2.8, -Math.PI * 0.25, 'sofa_right_1']]) {
    const couchGroup = new THREE.Group();
    couchGroup.position.set(sx, 0, sz);
    couchGroup.rotation.y = sAng;
    root.add(couchGroup);

    const seatCurve = box(2.6, 0.38, 0.9, new THREE.MeshStandardMaterial({ color: 0x161922, roughness: 0.28, metalness: 0.2 }), 0, 0.19, 0);
    const seatGoldBase = box(2.64, 0.05, 0.94, goldTrimMat, 0, 0.03, 0);
    const seatBack = box(2.6, 0.55, 0.22, new THREE.MeshStandardMaterial({ color: NEGRO_OBSIDIANA, roughness: 0.3 }), 0, 0.55, -0.34);
    seatCurve.userData.seatId = sId;
    seatBack.userData.seatId = sId;
    interactables.push(seatCurve, seatBack);
    couchGroup.add(seatCurve, seatGoldBase, seatBack);

    const potMesh = box(0.65, 0.55, 0.65, goldTrimMat, 1.6, 0.275, 0);
    const plantGlow = new THREE.Mesh(new THREE.DodecahedronGeometry(0.38), glow(VERDE_ESMERALDA, 2.4));
    plantGlow.position.set(1.6, 0.72, 0);
    couchGroup.add(potMesh, plantGlow);
  }

  // =========================================================================
  // 4D. SALA PRIVADA VIP: THE BOARDROOM (AMPLIADA, LUMINOSA Y CON LOGOS OFICIALES)
  // =========================================================================
  const boardroomRoot = new THREE.Group();
  boardroomRoot.name = 'premion_private_boardroom';
  const brCX = BOARDROOM_CENTER.x * S; // 26.0m
  const brCZ = BOARDROOM_CENTER.z * S; // 0.0m
  boardroomRoot.position.set(brCX, 0, brCZ);
  root.add(boardroomRoot);

  const brRadius = 7.4;
  const brHeight = 8.0;

  // 0. Iluminación Arquitectónica Dedicada de Alta Intensidad en Oro Cálido WordVerse
  const brMainLight = new THREE.PointLight(0xfff3d1, 88, 24, 1.15);
  brMainLight.position.set(0, 6.2, 0);
  boardroomRoot.add(brMainLight);

  for (const [lx, lz] of [[-4.4, -3.6], [4.4, -3.6], [-4.4, 3.6], [4.4, 3.6]]) {
    const pLight = new THREE.PointLight(0xffd978, 38, 16, 1.35);
    pLight.position.set(lx, 4.6, lz);
    boardroomRoot.add(pLight);
  }

  // 1. Suelo de Mármol Imperial Pulido con 3 Anillos Concéntricos en Oro WordVerse
  const brFloorMat = new THREE.MeshStandardMaterial({
    map: royalMarblePbrTexture({ w: 1024, h: 1024, tileCount: 6 }),
    roughness: 0.12,
    metalness: 0.35,
    envMapIntensity: 1.8,
  });
  const brFloor = new THREE.Mesh(new THREE.CircleGeometry(brRadius, 64), brFloorMat);
  brFloor.rotation.x = -Math.PI / 2;
  brFloor.receiveShadow = true;
  boardroomRoot.add(brFloor);

  // Anillos luminosos en el suelo de la sala privada en Oro WordVerse
  for (const [rIn, rOut, rCol] of [[3.2, 3.30, ORO_LUMINOSO], [4.4, 4.52, ORO_PREMIUM], [6.4, 6.54, ORO_PREMIUM]]) {
    const brRing = new THREE.Mesh(new THREE.RingGeometry(rIn, rOut, 64), glow(rCol, 2.5));
    brRing.rotation.x = -Math.PI / 2;
    brRing.position.y = 0.018;
    boardroomRoot.add(brRing);
  }

  // 2. Columnas Perimetrales en Oro Cepillado WordVerse + Muro Frontal con Monumento Oficial del Ecosistema
  const brWallMat = new THREE.MeshStandardMaterial({
    map: flutedWoodTexture({ w: 1024, h: 1024, slats: 32 }),
    roughness: 0.32,
    metalness: 0.65,
  });

  for (let colIdx = 0; colIdx < 8; colIdx++) {
    const cAng = (colIdx * Math.PI) / 4 + Math.PI / 8;
    const cx = Math.cos(cAng) * (brRadius - 0.35);
    const cz = Math.sin(cAng) * (brRadius - 0.35);
    const gCol = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.22, brHeight, 16), goldTrimMat);
    gCol.position.set(cx, brHeight / 2, cz);
    const gStrip = box(0.06, brHeight - 0.6, 0.06, glow(ORO_LUMINOSO, 2.4), cx * 0.96, brHeight / 2, cz * 0.96, false, false);
    boardroomRoot.add(gCol, gStrip);
  }

  // Muro frontal (Norte, Z negativa) con el Monumento Oficial del Ecosistema WordVerse (4 Logos Unidos en Oro)
  const brBackWall = box(8.8, brHeight - 0.6, 0.25, brWallMat, 0, brHeight / 2, -brRadius + 0.4);
  const brBackGoldFrame = box(9.0, brHeight - 0.4, 0.18, goldTrimMat, 0, brHeight / 2, -brRadius + 0.35);

  const ecoMonumentTex = texLoader.load('./assets/logo_ecosystem_monument.jpg');
  const brCenterCrestFrame = box(2.85, 2.85, 0.08, goldTrimMat, 0, 4.95, -brRadius + 0.54);
  const brCenterCrestGlow = box(2.92, 2.92, 0.04, glow(ORO_LUMINOSO, 2.2), 0, 4.95, -brRadius + 0.52, false, false);
  const brEmblemMesh = new THREE.Mesh(
    new THREE.PlaneGeometry(2.65, 2.65),
    new THREE.MeshBasicMaterial({
      map: ecoMonumentTex,
      side: THREE.FrontSide,
    }),
  );
  brEmblemMesh.position.set(0, 4.95, -brRadius + 0.60);
  boardroomRoot.add(brBackWall, brBackGoldFrame, brCenterCrestFrame, brCenterCrestGlow, brEmblemMesh);

  // 2B. 4 TÓTEMS CORPORATIVOS ILUMINADOS CON LOS LOGOS OFICIALES DE LAS EMPRESAS EN LA SALA PRIVADA VIP
  const boardroomBrandLogos = [
    {
      title: 'AURUM HEX',
      subtitle: 'SHEX · MMXXIV',
      imagePath: './assets/logo_aurum_shex.jpg',
      x: -4.15,
      z: -5.45,
      rotY: 0.28,
    },
    {
      title: 'SHEST COFFEE',
      subtitle: 'BITCOFFEE · VIP',
      imagePath: './assets/logo_b_coffee.jpg',
      x: 4.15,
      z: -5.45,
      rotY: -0.28,
    },
    {
      title: 'CYBER WOLF',
      subtitle: 'P2P PROTOCOL',
      imagePath: './assets/logo_cyber_wolf.jpg',
      x: -5.85,
      z: -1.65,
      rotY: Math.PI * 0.38,
    },
    {
      title: 'WORDVERSE VR',
      subtitle: 'METAVERSE HUB',
      imagePath: './assets/logo_wordverse_vr.jpg',
      x: 5.85,
      z: -1.65,
      rotY: -Math.PI * 0.38,
    },
  ];

  for (const bl of boardroomBrandLogos) {
    const totem = new THREE.Group();
    totem.position.set(bl.x, 0, bl.z);
    totem.rotation.y = bl.rotY;
    boardroomRoot.add(totem);

    // Pedestal y marco en Negro Obsidiana y Oro Cepillado WordVerse
    const tPedestal = box(1.95, 0.32, 0.36, goldTrimMat, 0, 0.16, 0);
    const tFrame = box(1.88, 2.85, 0.10, goldTrimMat, 0, 3.35, 0);
    const tGlow = box(1.94, 2.91, 0.05, glow(ORO_PREMIUM, 2.3), 0, 3.35, -0.02, false, false);
    const tBack = box(1.78, 2.75, 0.11, obsidianMat, 0, 3.35, 0.01);
    totem.add(tPedestal, tFrame, tGlow, tBack);

    // Imagen Oficial del Logo de la Empresa
    const bTex = texLoader.load(bl.imagePath);
    const bLogoMesh = new THREE.Mesh(
      new THREE.PlaneGeometry(1.58, 1.58),
      new THREE.MeshBasicMaterial({ map: bTex, side: THREE.DoubleSide }),
    );
    bLogoMesh.position.set(0, 3.68, 0.075);
    totem.add(bLogoMesh);

    // Placa Corporativa Dorada Inferior
    const bLabelTex = canvasTexture(512, 160, (ctx, w, h) => {
      ctx.fillStyle = '#0a0a0c';
      ctx.fillRect(0, 0, w, h);
      ctx.strokeStyle = '#d4af37';
      ctx.lineWidth = 6;
      ctx.strokeRect(4, 4, w - 8, h - 8);
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillStyle = '#ffffff';
      ctx.font = '900 38px "Segoe UI", sans-serif';
      ctx.fillText(bl.title, w / 2, 54);
      ctx.fillStyle = '#ffd978';
      ctx.font = '700 24px "Segoe UI", sans-serif';
      ctx.fillText(bl.subtitle, w / 2, 108);
    });
    const bLabelMesh = new THREE.Mesh(
      new THREE.PlaneGeometry(1.58, 0.52),
      new THREE.MeshBasicMaterial({ map: bLabelTex, side: THREE.DoubleSide }),
    );
    bLabelMesh.position.set(0, 2.48, 0.075);
    totem.add(bLabelMesh);

    // Luminaria cenital dorada sobre cada logo
    const bSpot = box(0.36, 0.08, 0.24, goldTrimMat, 0, 4.82, 0.14);
    const bSpotGlow = box(0.28, 0.025, 0.16, glow(ORO_LUMINOSO, 3.0), 0, 4.78, 0.14, false, false);
    totem.add(bSpot, bSpotGlow);
  }

  // Grandes ventanales angulados en los laterales con marcos de Oro WordVerse
  const brGlassMat = new THREE.MeshPhysicalMaterial({
    color: 0xffd978,
    transparent: true,
    opacity: 0.22,
    roughness: 0.04,
    metalness: 0.15,
    transmission: 0.90,
    ior: 1.52,
  });
  const brWinL = box(0.1, brHeight - 1.0, 7.6, brGlassMat, -brRadius + 0.4, brHeight / 2, 0, false, false);
  const brWinR = box(0.1, brHeight - 1.0, 7.6, brGlassMat, brRadius - 0.4, brHeight / 2, 0, false, false);
  boardroomRoot.add(brWinL, brWinR);

  // Skyline nocturno envolvente visible tras los ventanales norte, este y oeste de la sala privada
  const skyTexBr = panoramicSkylineTexture({ w: 2048, h: 512 });
  for (const [sx, sz, sRot] of [[0, -brRadius - 1.5, 0], [-brRadius - 1.5, 0, Math.PI / 2], [brRadius + 1.5, 0, -Math.PI / 2]]) {
    const brSky = new THREE.Mesh(
      new THREE.PlaneGeometry(22, 10),
      new THREE.MeshBasicMaterial({ map: skyTexBr, side: THREE.DoubleSide }),
    );
    brSky.position.set(sx, 4.5, sz);
    brSky.rotation.y = sRot;
    boardroomRoot.add(brSky);
  }

  // 3. Techo circular artesonado con Chandelier Imperial en Oro WordVerse (#D4AF37 / #FFD978)
  const brCeilMat = new THREE.MeshStandardMaterial({ color: NEGRO_OBSIDIANA, roughness: 0.4, metalness: 0.7 });
  const brCeil = new THREE.Mesh(new THREE.CircleGeometry(brRadius, 64), brCeilMat);
  brCeil.rotation.x = Math.PI / 2;
  brCeil.position.y = brHeight;
  boardroomRoot.add(brCeil);

  for (let ci = 0; ci < 4; ci++) {
    const cRad = 1.6 + ci * 1.45;
    const cRing = new THREE.Mesh(new THREE.TorusGeometry(cRad, 0.09, 12, 64), goldTrimMat);
    cRing.rotation.x = Math.PI / 2;
    cRing.position.y = brHeight - 0.15 - ci * 0.08;
    const cNeon = new THREE.Mesh(new THREE.TorusGeometry(cRad * 0.98, 0.035, 8, 64), glow(ci % 2 === 0 ? ORO_LUMINOSO : ORO_PREMIUM, 2.6));
    cNeon.rotation.x = Math.PI / 2;
    cNeon.position.y = brHeight - 0.16 - ci * 0.08;
    boardroomRoot.add(cRing, cNeon);
  }

  // 4. Gran Mesa Ejecutiva Central en Mármol Negro Obsidiana y Oro Cepillado WordVerse
  const brTableGroup = new THREE.Group();
  boardroomRoot.add(brTableGroup);

  const tableMat = new THREE.MeshStandardMaterial({
    map: royalMarblePbrTexture({ w: 1024, h: 1024, tileCount: 2 }),
    color: 0x161922,
    roughness: 0.08,
    metalness: 0.45,
    envMapIntensity: 2.0,
  });
  const brTableTop = new THREE.Mesh(new THREE.CylinderGeometry(2.45, 2.45, 0.12, 32), tableMat);
  brTableTop.position.y = 0.82;
  const brTableRim = new THREE.Mesh(new THREE.CylinderGeometry(2.50, 2.50, 0.14, 32), goldTrimMat);
  brTableRim.position.y = 0.81;
  const brTableGoldGlow = new THREE.Mesh(new THREE.TorusGeometry(2.51, 0.025, 8, 64), glow(ORO_LUMINOSO, 2.5));
  brTableGoldGlow.rotation.x = Math.PI / 2;
  brTableGoldGlow.position.y = 0.82;
  const brTableBase = new THREE.Mesh(new THREE.CylinderGeometry(1.45, 1.68, 0.74, 16), obsidianMat);
  brTableBase.position.y = 0.37;
  const brTableBaseGold = new THREE.Mesh(new THREE.CylinderGeometry(1.72, 1.76, 0.08, 16), goldTrimMat);
  brTableBaseGold.position.y = 0.04;
  brTableGroup.add(brTableTop, brTableRim, brTableGoldGlow, brTableBase, brTableBaseGold);

  // Medallones Dorados Incrustados en la Mesa Ejecutiva con los 4 Logos Oficiales de las Empresas
  const tableMedallionLogos = [
    { path: './assets/logo_aurum_shex.jpg', ang: Math.PI * 0.25 },
    { path: './assets/logo_b_coffee.jpg', ang: Math.PI * 0.75 },
    { path: './assets/logo_cyber_wolf.jpg', ang: Math.PI * 1.25 },
    { path: './assets/logo_wordverse_vr.jpg', ang: Math.PI * 1.75 },
  ];
  for (const tm of tableMedallionLogos) {
    const mx = Math.cos(tm.ang) * 1.92;
    const mz = Math.sin(tm.ang) * 1.92;
    const medDisc = new THREE.Mesh(
      new THREE.CircleGeometry(0.28, 32),
      new THREE.MeshBasicMaterial({ map: texLoader.load(tm.path) }),
    );
    medDisc.rotation.x = -Math.PI / 2;
    medDisc.rotation.z = -tm.ang + Math.PI / 2;
    medDisc.position.set(mx, 0.884, mz);
    const medRing = new THREE.Mesh(
      new THREE.RingGeometry(0.28, 0.31, 32),
      glow(ORO_PREMIUM, 2.2),
    );
    medRing.rotation.x = -Math.PI / 2;
    medRing.position.set(mx, 0.885, mz);
    brTableGroup.add(medDisc, medRing);
  }

  // 5. Holograma Central de Datos y Diapositivas Ejecutivas Interactivas (Ampliado y con Marco Dorado)
  let currentBoardroomSlide = 0;
  const slideTextures = BOARDROOM_SLIDES.map((_, i) => boardroomSlideTexture(i, { w: 1024, h: 512 }));

  const brScreenGroup = new THREE.Group();
  brScreenGroup.position.set(0, 1.98, -0.35);

  const brScreenMatFwd = new THREE.MeshBasicMaterial({
    map: slideTextures[0],
    transparent: true,
    opacity: 0.98,
    side: THREE.FrontSide,
  });
  const brScreenMatBwd = new THREE.MeshBasicMaterial({
    map: slideTextures[0],
    transparent: true,
    opacity: 0.98,
    side: THREE.FrontSide,
  });

  const screenGeo = new THREE.PlaneGeometry(2.85, 1.58);
  const brScreenFront = new THREE.Mesh(screenGeo, brScreenMatFwd);
  brScreenFront.position.z = 0.025;

  const brScreenBack = new THREE.Mesh(screenGeo, brScreenMatBwd);
  brScreenBack.rotation.y = Math.PI;
  brScreenBack.position.z = -0.025;

  const brFrame = new THREE.Mesh(
    new THREE.BoxGeometry(2.94, 1.66, 0.035),
    goldTrimMat
  );
  const brFrameGlow = new THREE.Mesh(
    new THREE.BoxGeometry(2.98, 1.70, 0.018),
    glow(ORO_LUMINOSO, 2.2)
  );

  brScreenGroup.add(brFrame, brFrameGlow, brScreenFront, brScreenBack);
  brTableGroup.add(brScreenGroup);

  const brHoloRing = new THREE.Mesh(new THREE.TorusGeometry(1.45, 0.035, 8, 48), glow(ORO_LUMINOSO, 2.6));
  brHoloRing.rotation.x = Math.PI / 2;
  brHoloRing.position.y = 0.90;
  brTableGroup.add(brHoloRing);

  function updateSlideDisplay(idx) {
    currentBoardroomSlide = (idx + BOARDROOM_SLIDES.length) % BOARDROOM_SLIDES.length;
    brScreenMatFwd.map = slideTextures[currentBoardroomSlide];
    brScreenMatFwd.needsUpdate = true;
    brScreenMatBwd.map = slideTextures[currentBoardroomSlide];
    brScreenMatBwd.needsUpdate = true;
    return BOARDROOM_SLIDES[currentBoardroomSlide];
  }

  function nextBoardroomSlide() {
    return updateSlideDisplay(currentBoardroomSlide + 1);
  }

  function prevBoardroomSlide() {
    return updateSlideDisplay(currentBoardroomSlide - 1);
  }

  function setBoardroomSlide(idx) {
    return updateSlideDisplay(idx);
  }

  // Consola flotante interactiva de presentador con botones táctiles 3D
  const presenterConsole = new THREE.Group();
  presenterConsole.position.set(0, 0.94, 1.65);
  brTableGroup.add(presenterConsole);

  const prevBtnMat = glow(CIAN_HOLO, 2.0);
  const nextBtnMat = glow(ORO_PREMIUM, 2.0);

  const prevBtnMesh = new THREE.Mesh(new THREE.BoxGeometry(0.32, 0.04, 0.16), prevBtnMat);
  prevBtnMesh.position.set(-0.25, 0, 0);
  prevBtnMesh.userData.isSlideButton = true;
  prevBtnMesh.userData.slideAction = 'prev';
  presenterConsole.add(prevBtnMesh);
  interactables.push(prevBtnMesh);

  const nextBtnMesh = new THREE.Mesh(new THREE.BoxGeometry(0.32, 0.04, 0.16), nextBtnMat);
  nextBtnMesh.position.set(0.25, 0, 0);
  nextBtnMesh.userData.isSlideButton = true;
  nextBtnMesh.userData.slideAction = 'next';
  presenterConsole.add(nextBtnMesh);
  interactables.push(nextBtnMesh);

  // Anillo de orador activo en el puesto principal (Host)
  const activeSpeakerRing = new THREE.Mesh(
    new THREE.RingGeometry(0.42, 0.48, 32),
    glow(VERDE_ESMERALDA, 2.5),
  );
  activeSpeakerRing.rotation.x = -Math.PI / 2;
  activeSpeakerRing.position.set(0, 0.025, 3.05);
  boardroomRoot.add(activeSpeakerRing);

  // Badge holográfico flotante de quórum / sesión VIP activa
  const brHoloStatusTex = canvasTexture(512, 120, (ctx, w, h) => {
    ctx.fillStyle = 'rgba(8, 10, 16, 0.92)';
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = '#d4af37';
    ctx.lineWidth = 3;
    ctx.strokeRect(3, 3, w - 6, h - 6);
    ctx.textAlign = 'center';
    ctx.fillStyle = '#ffd978';
    ctx.font = '900 22px "Segoe UI", Arial, sans-serif';
    ctx.fillText('🔒 THE BOARDROOM · SESIÓN VIP E2EE', w / 2, 46);
    ctx.fillStyle = '#00ff87';
    ctx.font = 'bold 15px "Segoe UI", Arial, sans-serif';
    ctx.fillText('🟢 QUÓRUM ACTIVO · AUDITORÍA ON-CHAIN', w / 2, 88);
  });
  const brHoloStatusSign = new THREE.Mesh(
    new THREE.PlaneGeometry(1.65, 0.40),
    new THREE.MeshBasicMaterial({ map: brHoloStatusTex, transparent: true, side: THREE.DoubleSide, toneMapped: false })
  );
  brHoloStatusSign.position.set(0, 2.65, 0);
  brTableGroup.add(brHoloStatusSign);

  animated.push((dt, t) => {
    brScreenGroup.position.y = 1.98 + Math.sin(t * 1.5) * 0.03;
    brHoloRing.scale.setScalar(1 + Math.sin(t * 2.2) * 0.04);
    brHoloStatusSign.rotation.y = t * 0.18;
    brHoloStatusSign.position.y = 2.65 + Math.sin(t * 1.8) * 0.03;
    activeSpeakerRing.scale.setScalar(1 + Math.sin(t * 3.5) * 0.05);
    activeSpeakerRing.material.opacity = 0.65 + Math.sin(t * 3.5) * 0.25;
  });

  // Motes cuánticos de datos orbitando el holograma central del Boardroom
  const brMoteCount = 38;
  const brGeo = new THREE.BufferGeometry();
  const brMotePos = new Float32Array(brMoteCount * 3);
  const brMoteAngles = new Float32Array(brMoteCount);
  const brMoteRadii = new Float32Array(brMoteCount);
  const brMoteSpeeds = new Float32Array(brMoteCount);

  for (let i = 0; i < brMoteCount; i++) {
    const ang = Math.random() * Math.PI * 2;
    const r = 0.65 + Math.random() * 0.75;
    brMoteAngles[i] = ang;
    brMoteRadii[i] = r;
    brMoteSpeeds[i] = 0.4 + Math.random() * 0.7;
    brMotePos[i * 3] = Math.cos(ang) * r;
    brMotePos[i * 3 + 1] = 1.0 + Math.random() * 1.4;
    brMotePos[i * 3 + 2] = Math.sin(ang) * r;
  }
  brGeo.setAttribute('position', new THREE.BufferAttribute(brMotePos, 3));
  const brMoteMat = new THREE.PointsMaterial({
    map: cyanDustTex,
    color: 0xc084fc,
    size: 0.08,
    transparent: true,
    opacity: 0.85,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  const brParticles = new THREE.Points(brGeo, brMoteMat);
  brTableGroup.add(brParticles);

  animated.push((dt, t) => {
    const arr = brGeo.attributes.position.array;
    for (let i = 0; i < brMoteCount; i++) {
      brMoteAngles[i] += dt * brMoteSpeeds[i];
      arr[i * 3] = Math.cos(brMoteAngles[i]) * brMoteRadii[i];
      arr[i * 3 + 1] = 1.0 + Math.sin(t * 1.5 + i) * 0.18 + ((i % 5) * 0.22);
      arr[i * 3 + 2] = Math.sin(brMoteAngles[i]) * brMoteRadii[i];
    }
    brGeo.attributes.position.needsUpdate = true;
  });

  // 6. Sillas Ejecutivas de Alta Dirección en Cuero y Oro WordVerse (8 Puestos a radio 3.05m)
  const brChairMat = new THREE.MeshStandardMaterial({
    map: quiltedLeatherTexture({ w: 512, h: 512, count: 4 }),
    roughness: 0.34,
    metalness: 0.25,
  });

  const emptySeatMap = {
    1: 'board_seat_se',
    2: 'board_seat_host',
    4: 'board_seat_west',
    7: 'board_seat_ne',
  };

  for (let ch = 0; ch < 8; ch++) {
    const chAng = (ch * Math.PI) / 4;
    const chX = Math.cos(chAng) * 3.05;
    const chZ = Math.sin(chAng) * 3.05;

    const chair = new THREE.Group();
    chair.position.set(chX, 0, chZ);
    chair.rotation.y = -chAng - Math.PI / 2; // Orientada hacia el centro de la mesa

    // Asiento, respaldo con ribete dorado y base en Oro WordVerse
    const chSeat = box(0.66, 0.1, 0.62, brChairMat, 0, 0.52, 0);
    const chBack = box(0.66, 0.78, 0.1, brChairMat, 0, 0.94, -0.26);
    const chGoldTrim = box(0.68, 0.04, 0.12, goldTrimMat, 0, 1.34, -0.26);
    const chLeg = new THREE.Mesh(new THREE.CylinderGeometry(0.045, 0.045, 0.48, 12), goldTrimMat);
    chLeg.position.y = 0.24;
    const chWheelBase = new THREE.Mesh(new THREE.CylinderGeometry(0.36, 0.36, 0.04, 5), goldTrimMat);
    chWheelBase.position.y = 0.04;
    chair.add(chSeat, chBack, chGoldTrim, chLeg, chWheelBase);
    boardroomRoot.add(chair);

    // Si es una silla libre para el jugador, hacerla clicable y añadir indicador sutil
    const seatId = emptySeatMap[ch];
    if (seatId) {
      for (const cm of [chSeat, chBack, chGoldTrim]) {
        cm.userData.seatId = seatId;
        interactables.push(cm);
      }
    }

    // Socios VIP sentados alrededor de la mesa con acabados ejecutivos dorados
    if (ch === 0 || ch === 3 || ch === 5 || ch === 6) {
      const partner = createAvatar({
        id: `board_vip_${ch}`,
        name: ch === 0 ? 'Director General' : (ch === 3 ? 'Socio Fundador' : (ch === 5 ? 'Directora Legal' : 'VP Finanzas')),
        company: 'WORDVERSE VIP',
        colorHex: ORO_PREMIUM,
        pose: 'sitting',
      });
      partner.group.position.set(chX, 0, chZ);
      partner.group.rotation.y = -chAng - Math.PI / 2;
      boardroomRoot.add(partner.group);
      interactables.push(...partner.hitTargets);
      allNpcAvatars.push(partner);
    }
  }

  // 7. Pórtico Abierto de Salida de la Sala Privada (Regreso al Punto de Entrada en Lobby)
  const brExitGroup = new THREE.Group();
  brExitGroup.position.set(-4.8, 0, 4.2);
  brExitGroup.rotation.y = Math.PI * 0.72;
  boardroomRoot.add(brExitGroup);

  const brExitColL = box(0.16, 3.3, 0.16, goldTrimMat, -1.05, 1.65, 0);
  const brExitColR = box(0.16, 3.3, 0.16, goldTrimMat, 1.05, 1.65, 0);
  const brExitLintel = box(2.35, 0.16, 0.20, glow(ORO_PREMIUM, 2.4), 0, 3.32, 0, false, false);
  const brExitVeil = new THREE.Mesh(
    new THREE.PlaneGeometry(1.94, 3.16),
    new THREE.MeshBasicMaterial({
      color: ORO_LUMINOSO,
      transparent: true,
      opacity: 0.14,
      side: THREE.DoubleSide,
      depthWrite: false,
    }),
  );
  brExitVeil.position.set(0, 1.62, 0);
  const brExitFloorRing = new THREE.Mesh(
    new THREE.RingGeometry(0.85, 0.94, 36),
    glow(ORO_LUMINOSO, 2.4),
  );
  brExitFloorRing.rotation.x = -Math.PI / 2;
  brExitFloorRing.position.set(0, 0.024, 0.25);

  const brExitSign = new THREE.Mesh(
    new THREE.PlaneGeometry(2.2, 0.58),
    new THREE.MeshBasicMaterial({
      map: premionPortalSignTexture({ title: 'SALIDA · SALA PÚBLICA', color: '#ffd978' }),
      transparent: true,
      side: THREE.DoubleSide,
    }),
  );
  brExitSign.position.set(0, 3.76, 0.04);
  for (const em of [brExitColL, brExitColR, brExitLintel, brExitVeil, brExitSign]) {
    em.userData.isBoardroomExit = true;
    interactables.push(em);
  }
  brExitGroup.add(brExitColL, brExitColR, brExitLintel, brExitVeil, brExitFloorRing, brExitSign);

  // =========================================================================
  // 5. CILINDRO CENTRAL MONUMENTAL "WORDVERSE" Y GLOBO HOLOGRÁFICO
  // Exacto al concept art media_1793083093848_9969c340.jpg
  // =========================================================================
  // 1. Podio circular escalonado con bordes en Oro y Cian
  const podiumGroup = new THREE.Group();
  podiumGroup.name = 'central_podium_group';
  root.add(podiumGroup);

  // Nivel inferior del podio: Negro obsidiana con aro de Oro Premium resplandeciente
  const podTier1 = new THREE.Mesh(
    new THREE.CylinderGeometry(2.35, 2.48, 0.22, 64),
    obsidianMat,
  );
  podTier1.position.y = 0.11;
  podTier1.receiveShadow = true;
  const podGoldRim1 = new THREE.Mesh(
    new THREE.TorusGeometry(2.46, 0.055, 12, 96),
    glow(ORO_PREMIUM, 3.0),
  );
  podGoldRim1.rotation.x = Math.PI / 2;
  podGoldRim1.position.y = 0.21;

  // Nivel superior del podio: Escudo de soporte con aro de Cian Neón
  const podTier2 = new THREE.Mesh(
    new THREE.CylinderGeometry(2.05, 2.15, 0.18, 64),
    new THREE.MeshStandardMaterial({ color: 0x111827, roughness: 0.2, metalness: 0.7 }),
  );
  podTier2.position.y = 0.31;
  const podCyanRim = new THREE.Mesh(
    new THREE.TorusGeometry(2.14, 0.045, 12, 96),
    glow(CIAN_HOLO, 2.8),
  );
  podCyanRim.rotation.x = Math.PI / 2;
  podCyanRim.position.y = 0.39;

  // Collar biselado de Oro que ancla el cilindro
  const podCollar = new THREE.Mesh(
    new THREE.TorusGeometry(1.88, 0.04, 12, 64),
    glow(ORO_PREMIUM, 2.6),
  );
  podCollar.rotation.x = Math.PI / 2;
  podCollar.position.y = 0.42;

  podiumGroup.add(podTier1, podGoldRim1, podTier2, podCyanRim, podCollar);

  // 2. Gran Cilindro LED Central "WORDVERSE" (Apoyado sobre el podio)
  const drumTex = wordverseCentralDrumTexture({ w: 2048, h: 1024 });
  const centralCylinder = new THREE.Mesh(
    new THREE.CylinderGeometry(1.85, 1.85, 3.75, 64, 1, true),
    new THREE.MeshBasicMaterial({
      map: drumTex,
      side: THREE.DoubleSide,
      toneMapped: false,
    }),
  );
  centralCylinder.position.y = 2.28;
  root.add(centralCylinder);

  // Corona superior biselada del cilindro en Oro Premium
  const cylCrownGold = new THREE.Mesh(
    new THREE.TorusGeometry(1.88, 0.05, 12, 64),
    glow(ORO_PREMIUM, 2.8),
  );
  cylCrownGold.rotation.x = Math.PI / 2;
  cylCrownGold.position.y = 4.16;
  root.add(cylCrownGold);

  // Núcleo cilíndrico interno con resplandor aditivo cian suave
  const innerGlowCyl = new THREE.Mesh(
    new THREE.CylinderGeometry(1.82, 1.82, 3.72, 32, 1, true),
    new THREE.MeshBasicMaterial({
      color: 0x00f0ff,
      transparent: true,
      opacity: 0.16,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      toneMapped: false,
    }),
  );
  innerGlowCyl.position.y = 2.28;
  root.add(innerGlowCyl);

  // 3. Globo Holográfico Geodésico sobre la cima del cilindro
  const globeGroup = new THREE.Group();
  globeGroup.position.set(0, 5.15, 0);
  root.add(globeGroup);

  // Esfera geodésica alámbrica en Cian Neón
  const globeWire = new THREE.Mesh(
    new THREE.IcosahedronGeometry(0.95, 2),
    new THREE.MeshBasicMaterial({
      color: 0x00f0ff,
      wireframe: true,
      toneMapped: false,
    }),
  );
  // Núcleo holográfico interior brillante
  const globeCore = new THREE.Mesh(
    new THREE.SphereGeometry(0.55, 24, 24),
    glow(CIAN_HOLO, 2.6),
  );
  // Anillo meridiano orbital
  const globeRing1 = new THREE.Mesh(
    new THREE.TorusGeometry(1.22, 0.035, 8, 48),
    glow(CIAN_HOLO, 2.2),
  );
  globeRing1.rotation.x = 0.45;
  const globeRing2 = new THREE.Mesh(
    new THREE.TorusGeometry(1.35, 0.028, 8, 48),
    glow(ORO_PREMIUM, 2.2),
  );
  globeRing2.rotation.x = -0.55;
  globeRing2.rotation.z = 0.35;
  globeGroup.add(globeWire, globeCore, globeRing1, globeRing2);

  // Rótulo holográfico giratorio de la Red Global WordVerse
  const holoNetTex = canvasTexture(640, 140, (ctx, w, h) => {
    ctx.fillStyle = 'rgba(6, 12, 22, 0.90)';
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = '#00f0ff';
    ctx.lineWidth = 3;
    ctx.strokeRect(4, 4, w - 8, h - 8);
    ctx.textAlign = 'center';
    ctx.fillStyle = '#00f0ff';
    ctx.font = '900 24px "Segoe UI", Arial, sans-serif';
    ctx.fillText('🌐 RED GLOBAL WORDVERSE', w / 2, 48);
    ctx.fillStyle = '#ffd978';
    ctx.font = 'bold 16px "Segoe UI", Arial, sans-serif';
    ctx.fillText('48 NODOS ACTIVOS · LIQUIDEZ & ESCROW ON', w / 2, 94);
  });
  const holoNetSign = new THREE.Mesh(
    new THREE.PlaneGeometry(1.8, 0.42),
    new THREE.MeshBasicMaterial({ map: holoNetTex, transparent: true, side: THREE.DoubleSide, toneMapped: false })
  );
  holoNetSign.position.set(0, 1.45, 0);
  globeGroup.add(holoNetSign);

  // 4. Techo Artesonado Concéntrico (Bandejas de Oro y Negro con Halos Neón sobre el Cilindro)
  const cofferedCeilingGroup = new THREE.Group();
  cofferedCeilingGroup.position.set(0, 8.8, 0);
  root.add(cofferedCeilingGroup);

  const cofferRings = [
    { r: 2.3, h: 0.24, col: ORO_PREMIUM, glowCol: CIAN_HOLO },
    { r: 3.3, h: 0.32, col: NEGRO_OBSIDIANA, glowCol: PURPURA_NEB },
    { r: 4.4, h: 0.40, col: ORO_PREMIUM, glowCol: CIAN_HOLO },
  ];
  for (const [idx, cr] of cofferRings.entries()) {
    const soffit = new THREE.Mesh(
      new THREE.CylinderGeometry(cr.r, cr.r + 0.18, cr.h, 64, 1, true),
      new THREE.MeshStandardMaterial({ color: cr.col, roughness: 0.25, metalness: 0.75 }),
    );
    soffit.position.y = idx * 0.26;
    const neonHalo = new THREE.Mesh(
      new THREE.TorusGeometry(cr.r + 0.08, 0.045, 8, 96),
      glow(cr.glowCol, 1.25),
    );
    neonHalo.rotation.x = Math.PI / 2;
    neonHalo.position.y = idx * 0.26 - cr.h / 2;
    cofferedCeilingGroup.add(soffit, neonHalo);
  }

  // 5. Tapete de Suelo en frente del Cilindro: [W] WORDVERSE
  const floorMatMesh = new THREE.Mesh(
    new THREE.PlaneGeometry(3.6, 1.45),
    new THREE.MeshBasicMaterial({
      map: wordverseFloorMatTexture({ w: 1024, h: 420 }),
      toneMapped: false,
    }),
  );
  floorMatMesh.rotation.x = -Math.PI / 2;
  floorMatMesh.position.set(0, 0.024, 2.45);
  root.add(floorMatMesh);

  // 6. Círculos de Encuentro / Networking en el Suelo (Verde, Púrpura, Cian)
  const meetingSpots = [
    { x: -2.3, z: 2.2, r: 0.72, col: '#ec4899', hex: 0xec4899 }, // Púrpura/Rosa (Frente Izq)
    { x: 2.3, z: 2.2, r: 0.72, col: '#00ff87', hex: VERDE_ESMERALDA }, // Verde Esmeralda (Frente Der)
    { x: 4.8, z: 1.2, r: 0.65, col: '#00f0ff', hex: CIAN_HOLO }, // Cian (Lateral Der)
    { x: -4.4, z: 1.2, r: 0.65, col: '#ec4899', hex: 0xec4899 }, // Rosa (Lateral Izq)
  ];
  for (const ms of meetingSpots) {
    const padRing = new THREE.Mesh(
      new THREE.RingGeometry(ms.r - 0.05, ms.r + 0.05, 48),
      glow(ms.hex, 2.8),
    );
    padRing.rotation.x = -Math.PI / 2;
    padRing.position.set(ms.x, 0.022, ms.z);
    root.add(padRing);
  }

  // 7. Paneles Murales Monumentales PREMION (Oro y Negro)
  // Panel Mural Izquierdo (Pared Planta Baja)
  const wallPanelLeft = new THREE.Mesh(
    new THREE.PlaneGeometry(2.8, 3.4),
    new THREE.MeshBasicMaterial({
      map: premionWallGoldPanelTexture({ w: 1024, h: 1240 }),
    }),
  );
  wallPanelLeft.position.set(-HALF + 0.16, 2.4, 1.4);
  wallPanelLeft.rotation.y = Math.PI / 2;
  root.add(wallPanelLeft);

  // Mostrador Ejecutivo con Placa Flotante de Valeria Mendez (Ubicado en el cuadrante Suroeste para dejar libre la bahía del Ascensor)
  const valeriaDeskGroup = new THREE.Group();
  valeriaDeskGroup.position.set(-HALF + 1.2, 0, 5.4);
  valeriaDeskGroup.rotation.y = Math.PI / 2;
  root.add(valeriaDeskGroup);

  const vDeskBody = box(1.8, 0.9, 0.65, obsidianMat, 0, 0.45, 0);
  const vDeskTop = box(1.9, 0.08, 0.72, goldTrimMat, 0, 0.94, 0);
  const vDeskGoldTrim = box(1.88, 0.04, 0.70, glow(ORO_PREMIUM, 2.2), 0, 0.90, 0, false, false);
  valeriaDeskGroup.add(vDeskBody, vDeskTop, vDeskGoldTrim);

  // Placa Neón Flotante: Valeria Mendez · STATUS: AVAILABLE · Director
  const vBadgeMesh = new THREE.Mesh(
    new THREE.PlaneGeometry(1.15, 0.48),
    new THREE.MeshBasicMaterial({
      map: valeriaMendezBadgeTexture({ w: 512, h: 220 }),
      transparent: true,
      toneMapped: false,
    }),
  );
  vBadgeMesh.position.set(-HALF + 1.2, 1.52, 5.4);
  vBadgeMesh.rotation.y = Math.PI / 2;
  root.add(vBadgeMesh);

  // Avatar Ejecutivo de Valeria Mendez de pie tras su mostrador
  const valeriaAvatar = createAvatar({
    id: 'valeria_mendez',
    name: 'Valeria Mendez',
    company: 'WORDVERSE • Director',
    status: 'ONLINE',
    colorHex: ORO_PREMIUM,
    pose: 'standing',
  });
  valeriaAvatar.group.position.set(-HALF + 1.55, 0, 5.4);
  valeriaAvatar.group.rotation.y = Math.PI / 2;
  root.add(valeriaAvatar.group);
  interactables.push(...valeriaAvatar.hitTargets);
  allNpcAvatars.push(valeriaAvatar);

  // Panel Mural Derecho (Pared Planta Baja)
  const wallPanelRight = new THREE.Mesh(
    new THREE.PlaneGeometry(2.8, 3.4),
    new THREE.MeshBasicMaterial({
      map: premionWallGoldPanelTexture({ w: 1024, h: 1240 }),
    }),
  );
  wallPanelRight.position.set(HALF - 0.16, 2.4, 1.4);
  wallPanelRight.rotation.y = -Math.PI / 2;
  root.add(wallPanelRight);

  // Pantalla Holográfica de Biometría / AI (#OFFERS y APPROVED)
  const bioScreenMesh = new THREE.Mesh(
    new THREE.PlaneGeometry(2.6, 2.6),
    new THREE.MeshBasicMaterial({
      map: biometricAiScreenTexture({ w: 1024, h: 1024 }),
      transparent: true,
      toneMapped: false,
    }),
  );
  bioScreenMesh.position.set(HALF - 0.16, 2.2, 3.4);
  bioScreenMesh.rotation.y = -Math.PI / 2;
  root.add(bioScreenMesh);

  // Gran Pantalla de Comando Táctico Mundial en Mezzanine (Ala Izquierda)
  const cmdMapMesh = new THREE.Mesh(
    new THREE.PlaneGeometry(5.4, 2.7),
    new THREE.MeshBasicMaterial({
      map: curvedCommandCenterMapTexture({ w: 2048, h: 1024 }),
      toneMapped: false,
    }),
  );
  cmdMapMesh.position.set(-HALF + 0.26, MEZZANINE_Y + 2.1, -1.2);
  cmdMapMesh.rotation.y = Math.PI / 2;
  root.add(cmdMapMesh);

  // Holograma Flotante de Ethereum en 3D (Cian y Púrpura)
  const ethGroup = new THREE.Group();
  ethGroup.position.set(2.8, 3.4, -1.6);
  root.add(ethGroup);

  const ethTop = new THREE.Mesh(new THREE.ConeGeometry(0.38, 0.75, 4), glow(CIAN_HOLO, 2.6));
  ethTop.position.y = 0.38;
  const ethBot = new THREE.Mesh(new THREE.ConeGeometry(0.38, 0.55, 4), glow(PURPURA_NEB, 2.6));
  ethBot.rotation.x = Math.PI;
  ethBot.position.y = -0.28;
  ethGroup.add(ethTop, ethBot);

  // 8. Avatares Ejecutivos en Conversación y Descanso Estilo GTA V
  const socialAvatarsData = [
    // Pareja en Círculo Verde Esmeralda (Traders P2P / Escrow)
    { id: 'p2p_trader_1', name: 'Carlos Rivas', company: 'P2P Trader', status: 'VERIFIED', col: VERDE_ESMERALDA, x: 2.1, z: 2.2, rot: Math.PI * 0.45, pose: 'standing' },
    { id: 'escrow_broker_2', name: 'Elena Vance', company: 'Escrow Broker', status: 'ONLINE', col: ORO_PREMIUM, x: 2.5, z: 2.2, rot: -Math.PI * 0.45, pose: 'tablet' },
    // Pareja en Círculo Púrpura (Socios de Negocios)
    { id: 'partner_marcus', name: 'Marcus Sterling', company: 'Venture Partner', status: 'VIP', col: PURPURA_NEB, x: -2.1, z: 2.2, rot: Math.PI * 0.4, pose: 'tablet' },
    { id: 'analyst_sofia', name: 'Sofia Chen', company: 'Lead Analyst', status: 'ONLINE', col: CIAN_HOLO, x: -2.5, z: 2.2, rot: -Math.PI * 0.5, pose: 'standing' },
    // Ejecutivos Sentados en los Sillones Lounge del Lobby
    { id: 'lounge_seated_1', name: 'Mateo Rossi', company: 'Inversor Ángel', status: 'VIP', col: ORO_PREMIUM, x: -4.5, y: 0, z: 4.3, rot: Math.PI * 0.25, pose: 'sitting' },
    { id: 'lounge_seated_2', name: 'Laura Gómez', company: 'Fondo Cripto', status: 'ONLINE', col: CIAN_HOLO, x: 4.5, y: 0, z: 2.7, rot: -Math.PI * 0.25, pose: 'sitting' },
    // Avatar de pie en Mezzanine mirando hacia el atrio
    { id: 'mezzanine_exec_1', name: 'VP Operaciones', company: 'PREMION Mezzanine', status: 'VIP', col: ORO_PREMIUM, x: -3.2, y: MEZZANINE_Y, z: -4.1, rot: 0, pose: 'standing' },
    { id: 'mezzanine_exec_2', name: 'VP Estrategia', company: 'PREMION Mezzanine', status: 'VIP', col: CIAN_HOLO, x: 3.2, y: MEZZANINE_Y, z: -4.1, rot: 0, pose: 'standing' },
  ];

  for (const ad of socialAvatarsData) {
    const socAv = createAvatar({
      id: ad.id,
      name: ad.name,
      company: ad.company,
      status: ad.status,
      colorHex: ad.col,
      pose: ad.pose,
    });
    socAv.group.position.set(ad.x, ad.y || 0, ad.z);
    socAv.group.rotation.y = ad.rot;
    if (socAv.plate) socAv.plate.visible = false;
    root.add(socAv.group);
    interactables.push(...socAv.hitTargets);
    allNpcAvatars.push(socAv);
  }

  // Animaciones continuas del cilindro, globo y holograma de Ethereum
  animated.push((dt, t) => {
    centralCylinder.rotation.y = t * 0.12;
    globeWire.rotation.y = t * 0.4;
    globeWire.rotation.x = Math.sin(t * 0.5) * 0.15;
    globeRing1.rotation.y = -t * 0.6;
    globeRing2.rotation.z = t * 0.5;
    holoNetSign.rotation.y = -t * 0.35;
    holoNetSign.position.y = 1.45 + Math.sin(t * 2.0) * 0.04;
    ethGroup.rotation.y = t * 0.8;
    ethGroup.position.y = 3.4 + Math.sin(t * 1.8) * 0.12;
  });

  // Aros orbitales holográficos concéntricos con contra-rotación
  const ringMat1 = glow(CYAN, 2.4);
  const ringMat2 = glow(0xa855f7, 2.2);
  const ring1 = new THREE.Mesh(new THREE.TorusGeometry(1.85, 0.022, 8, 64), ringMat1);
  ring1.position.y = 2.2;
  ring1.rotation.x = 0.35;
  const ring2 = new THREE.Mesh(new THREE.TorusGeometry(2.15, 0.018, 8, 64), ringMat2);
  ring2.position.y = 2.2;
  ring2.rotation.x = -0.4;
  ring2.rotation.z = 0.25;
  root.add(ring1, ring2);

  // 4 Badges Financieros Ticker Orbitantes (Estilo GTA VI / Cyberpunk Escrow)
  const tickersData = [
    { symbol: '₿', title: 'BTC / USDT', value: '$96,420', change: '+3.4% 24h', color: '#f59e0b' },
    { symbol: '🛡️', title: 'ESCROW TOTAL 24H', value: '$4,850,000', change: '+12.8% Vol', color: '#10b981' },
    { symbol: '⚡', title: 'P2P RED TRC20', value: '38s Vel. Media', change: '● 99.9% Red', color: '#06b6d4' },
    { symbol: '💎', title: 'SHEST TOKEN VIP', value: '$4.82 USDT', change: '+7.2% APY', color: '#a855f7' },
  ];
  const tickerGroup = new THREE.Group();
  tickerGroup.name = 'orbiting_tickers';
  root.add(tickerGroup);

  const tickerMeshes = tickersData.map((td, i) => {
    const mesh = new THREE.Mesh(
      new THREE.PlaneGeometry(0.95, 0.32),
      new THREE.MeshBasicMaterial({
        map: tickerCardTexture(td),
        transparent: true,
        side: THREE.DoubleSide,
        depthWrite: false,
        toneMapped: false,
      }),
    );
    tickerGroup.add(mesh);
    return { mesh, baseAng: (i * Math.PI) / 2 };
  });

  // Torrente ascendente de partículas cibernéticas de datos (Data Stream)
  const cyberParticleCount = 48;
  const streamGeo = new THREE.BufferGeometry();
  const streamPositions = new Float32Array(cyberParticleCount * 3);
  const streamSpeeds = new Float32Array(cyberParticleCount);
  const streamAngles = new Float32Array(cyberParticleCount);
  const streamRadii = new Float32Array(cyberParticleCount);

  for (let i = 0; i < cyberParticleCount; i++) {
    const ang = Math.random() * Math.PI * 2;
    const r = 0.35 + Math.random() * 1.35;
    streamPositions[i * 3] = Math.cos(ang) * r;
    streamPositions[i * 3 + 1] = 0.3 + Math.random() * 8.5;
    streamPositions[i * 3 + 2] = Math.sin(ang) * r;
    streamSpeeds[i] = 0.85 + Math.random() * 1.4;
    streamAngles[i] = ang;
    streamRadii[i] = r;
  }
  streamGeo.setAttribute('position', new THREE.BufferAttribute(streamPositions, 3));
  const streamMat = new THREE.PointsMaterial({
    color: 0x38bdf8,
    size: 0.075,
    transparent: true,
    opacity: 0.85,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  const particleStream = new THREE.Points(streamGeo, streamMat);
  root.add(particleStream);

  animated.push((dt, t) => {
    ring1.rotation.z = t * 0.45;
    ring2.rotation.y = -t * 0.35;

    // Órbita fluida de badges ticker en la corona superior del cilindro (sin obstruir la cámara a nivel de piso)
    const orbitR = 2.15;
    tickerMeshes.forEach(({ mesh, baseAng }, idx) => {
      const ang = t * 0.26 + baseAng;
      const yOff = Math.sin(t * 1.6 + idx * 1.5) * 0.10;
      mesh.position.set(Math.cos(ang) * orbitR, 4.45 + yOff, Math.sin(ang) * orbitR);
      mesh.rotation.y = -ang + Math.PI / 2;
    });

    // Ascenso de partículas de datos
    const pos = streamGeo.attributes.position.array;
    for (let i = 0; i < cyberParticleCount; i++) {
      streamAngles[i] += dt * 0.35;
      pos[i * 3] = Math.cos(streamAngles[i]) * streamRadii[i];
      pos[i * 3 + 1] += dt * streamSpeeds[i];
      pos[i * 3 + 2] = Math.sin(streamAngles[i]) * streamRadii[i];
      if (pos[i * 3 + 1] > 8.8) {
        pos[i * 3 + 1] = 0.3;
      }
    }
    streamGeo.attributes.position.needsUpdate = true;
  });

  // =========================================================================
  // 7. RECEPCIÓN WORDVERSE (Cuadrante Inferior Derecho)
  // =========================================================================
  const recB = BOXES.receptionDesk;
  const recW = (recB.maxX - recB.minX) * S;
  const recD = (recB.maxZ - recB.minZ) * S;
  const recCX = ((recB.minX + recB.maxX) / 2) * S;
  const recCZ = ((recB.maxZ + recB.minZ) / 2) * S;

  // Mostrador de recepción en Negro Obsidiana y Ónix Dorado retroiluminado (Paleta WordVerse)
  const deskOnyxMat = new THREE.MeshStandardMaterial({
    map: backlitOnyxTexture({ w: 1024, h: 512, color: '#d4af37' }),
    roughness: 0.16,
    metalness: 0.55,
    envMapIntensity: 1.5,
  });
  const deskBody = box(recW, 1.05, recD, deskOnyxMat, recCX, 0.525, recCZ);
  const deskTop = box(recW + 0.14, 0.08, recD + 0.12, goldTrimMat, recCX, 1.08, recCZ);
  const deskGlow = box(recW, 0.08, recD + 0.04, glow(ORO_PREMIUM, 2.6), recCX, 0.15, recCZ, false, false);
  root.add(deskBody, deskTop, deskGlow);

  // Muro arquitectónico de fondo con Palillería de Nogal y fosa de luz ámbar
  const recWoodWall = box(recW * 1.35, 4.4, 0.1, new THREE.MeshStandardMaterial({
    map: flutedWoodTexture({ w: 1024, h: 1024, slats: 36 }),
    roughness: 0.6,
    metalness: 0.12,
  }), recCX, 2.2, recCZ + recD / 2 + 0.95);
  const recWoodGlow = box(recW * 1.37, 4.42, 0.04, glow(0xf59e0b, 1.5), recCX, 2.2, recCZ + recD / 2 + 1.0, false, false);

  // Placa Emblemática Hexagonal PREMION 3D BUSINESS HUB - LOBBY
  const lobbyEmblem = new THREE.Mesh(
    new THREE.PlaneGeometry(2.6, 2.6),
    new THREE.MeshBasicMaterial({
      map: premionEmblemTexture({ type: 'lobby' }),
      transparent: true,
    }),
  );
  lobbyEmblem.position.set(recCX, 2.8, recCZ + recD / 2 + 0.88);
  lobbyEmblem.rotation.y = Math.PI;
  root.add(recWoodWall, recWoodGlow, lobbyEmblem);

  // Logo WordVerse en el frontal del mostrador
  const recLogo = new THREE.Mesh(
    new THREE.PlaneGeometry(1.6, 0.55),
    new THREE.MeshBasicMaterial({
      map: canvasTexture(512, 180, (ctx, ww, hh) => {
        drawLogo(ctx, 80, hh / 2, 55);
        ctx.fillStyle = '#ffffff';
        ctx.font = 'bold 56px "Segoe UI", Arial, sans-serif';
        ctx.textAlign = 'left';
        ctx.textBaseline = 'middle';
        ctx.fillText('WordVerse', 155, hh / 2 + 4);
      }),
      transparent: true,
    }),
  );
  recLogo.position.set(recCX, 0.65, recB.minZ * S - 0.02);
  recLogo.rotation.y = Math.PI;
  root.add(recLogo);

  // Monitores finos sobre el mostrador
  for (const mx of [-0.9, 0.9]) {
    const monitor = box(0.48, 0.32, 0.04, new THREE.MeshStandardMaterial({ color: 0x020617 }), recCX + mx, 1.35, recCZ - 0.05);
    const screenGlow = box(0.45, 0.29, 0.01, glow(0x7dd3fc, 1.2), recCX + mx, 1.35, recCZ - 0.02, false, false);
    root.add(monitor, screenGlow);
  }

  // =========================================================================
  // 7A. NÚCLEO HOLOGRÁFICO "NEXUS AI" EN LA RECEPCIÓN CENTRAL
  // =========================================================================
  let nexusAiSpeaking = false;
  const nexusCoreGroup = new THREE.Group();
  nexusCoreGroup.position.set(recCX, 1.12, recCZ - 0.02);
  root.add(nexusCoreGroup);

  const emitterBase = new THREE.Mesh(
    new THREE.CylinderGeometry(0.30, 0.35, 0.05, 24),
    new THREE.MeshStandardMaterial({ color: ORO_PREMIUM, metalness: 0.92, roughness: 0.18 })
  );
  const emitterRing = new THREE.Mesh(
    new THREE.TorusGeometry(0.32, 0.018, 8, 32),
    glow(CIAN_HOLO, 2.5)
  );
  emitterRing.rotation.x = Math.PI / 2;
  emitterRing.position.y = 0.03;

  const aiOrbOuter = new THREE.Mesh(
    new THREE.IcosahedronGeometry(0.22, 1),
    new THREE.MeshBasicMaterial({ color: CIAN_HOLO, wireframe: true, transparent: true, opacity: 0.85 })
  );
  aiOrbOuter.position.y = 0.38;
  aiOrbOuter.userData.isNexusAi = true;
  interactables.push(aiOrbOuter);

  const aiOrbInner = new THREE.Mesh(
    new THREE.SphereGeometry(0.11, 16, 16),
    glow(VERDE_ESMERALDA, 2.8)
  );
  aiOrbInner.position.y = 0.38;
  aiOrbInner.userData.isNexusAi = true;
  interactables.push(aiOrbInner);

  const aiGyroGold = new THREE.Mesh(
    new THREE.TorusGeometry(0.28, 0.012, 8, 32),
    glow(ORO_PREMIUM, 2.2)
  );
  aiGyroGold.position.y = 0.38;

  const aiGyroCyan = new THREE.Mesh(
    new THREE.TorusGeometry(0.33, 0.01, 8, 32),
    glow(CIAN_HOLO, 2.0)
  );
  aiGyroCyan.position.y = 0.38;
  aiGyroCyan.rotation.x = Math.PI / 3;

  // Anillo de onda de voz neural (se expande cuando Nexus AI habla)
  const aiVoiceWaveMat = new THREE.MeshBasicMaterial({
    color: VERDE_ESMERALDA,
    transparent: true,
    opacity: 0.0,
    side: THREE.DoubleSide,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  const aiVoiceWaveRing = new THREE.Mesh(
    new THREE.RingGeometry(0.32, 0.42, 32),
    aiVoiceWaveMat
  );
  aiVoiceWaveRing.rotation.x = -Math.PI / 2;
  aiVoiceWaveRing.position.y = 0.06;

  // Placa Holográfica Flotante sobre el Núcleo Nexus AI
  const nexusBanner = new THREE.Mesh(
    new THREE.PlaneGeometry(1.75, 0.48),
    new THREE.MeshBasicMaterial({
      map: canvasTexture(640, 176, (ctx, w, h) => {
        ctx.fillStyle = 'rgba(6, 10, 18, 0.90)';
        ctx.beginPath();
        ctx.roundRect(6, 6, w - 12, h - 12, 22);
        ctx.fill();
        ctx.lineWidth = 4;
        ctx.strokeStyle = '#00f0ff';
        ctx.stroke();

        ctx.fillStyle = '#00ff87';
        ctx.font = '900 22px "Segoe UI", Arial, sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText('🤖 NEXUS AI · COPILOTO HOLOGRÁFICO', w / 2, 62);

        ctx.fillStyle = '#ffd978';
        ctx.font = 'bold 18px "Segoe UI", Arial, sans-serif';
        ctx.fillText('CONSERJE 24/7 & MINUTAS IA · [E / N / CLIC]', w / 2, 118);
      }),
      transparent: true,
      side: THREE.FrontSide,
    })
  );
  nexusBanner.position.y = 0.92;
  nexusBanner.rotation.y = Math.PI;
  nexusBanner.userData.isNexusAi = true;
  interactables.push(nexusBanner);

  nexusCoreGroup.add(emitterBase, emitterRing, aiOrbOuter, aiOrbInner, aiGyroGold, aiGyroCyan, aiVoiceWaveRing, nexusBanner);

  animated.push((dt, t) => {
    const speedMult = nexusAiSpeaking ? 3.4 : 1.0;
    aiOrbOuter.rotation.y += dt * 0.85 * speedMult;
    aiOrbOuter.rotation.x += dt * 0.45 * speedMult;
    aiGyroGold.rotation.y -= dt * 1.2 * speedMult;
    aiGyroGold.rotation.z += dt * 0.6 * speedMult;
    aiGyroCyan.rotation.x += dt * 1.1 * speedMult;

    const floatY = 0.38 + Math.sin(t * 2.4) * 0.035;
    aiOrbOuter.position.y = floatY;
    aiOrbInner.position.y = floatY;
    aiGyroGold.position.y = floatY;
    aiGyroCyan.position.y = floatY;
    nexusBanner.position.y = 0.92 + Math.sin(t * 2.0) * 0.025;

    if (nexusAiSpeaking) {
      const pulse = 1 + Math.sin(t * 14) * 0.25;
      aiOrbInner.scale.setScalar(pulse);
      const wavePhase = (t * 2.2) % 1;
      aiVoiceWaveRing.scale.setScalar(1 + wavePhase * 2.6);
      aiVoiceWaveMat.opacity = (1 - wavePhase) * 0.85;
    } else {
      aiOrbInner.scale.setScalar(1 + Math.sin(t * 3.0) * 0.08);
      aiVoiceWaveMat.opacity = 0.0;
    }
  });

  // =========================================================================
  // 7B. POBLACIÓN EJECUTIVA AUTÓNOMA Y SISTEMA DE PATRULLAJE IA (GTA VI ESTÁNDAR)
  // =========================================================================
  const patrolNPCs = [
    {
      id: 'npc_elena',
      name: 'Elena Rostova',
      company: 'VP Global Escrow',
      status: 'Disponible',
      affinity: 96,
      specialty: 'Liquidez P2P & Escrow TRC20',
      colorHex: 0x22d3ee,
      pose: 'standing',
      speed: 1.15,
      y: 0,
      waypoints: [
        { x: 2.4, z: 0.3, wait: 4.5, emote: '📊' },
        { x: 3.6, z: -0.8, wait: 3.5, emote: '💼' },
        { x: 2.8, z: 2.2, wait: 4.0, emote: '🤝' },
        { x: 0.6, z: 1.8, wait: 3.0, emote: '📈' },
      ],
      currentWp: 0,
      waitTimer: 2.0,
      greetTimer: 0,
    },
    {
      id: 'npc_marcus',
      name: 'Marcus Chen',
      company: 'Auditor de Seguridad P2P',
      status: 'Disponible',
      affinity: 93,
      specialty: 'Auditoría Multi-Firma E2EE',
      colorHex: 0x38bdf8,
      pose: 'tablet',
      speed: 0.95,
      y: 0,
      waypoints: [
        { x: -2.8, z: 1.8, wait: 4.0, emote: '🛡️' },
        { x: -1.6, z: 3.2, wait: 3.5, emote: '🔍' },
        { x: -3.4, z: 0.2, wait: 4.5, emote: '⚡' },
      ],
      currentWp: 0,
      waitTimer: 1.0,
      greetTimer: 0,
    },
    {
      id: 'npc_sofia',
      name: 'Sofía Herrera',
      company: 'Directora VIP Mezzanine',
      status: 'Disponible',
      affinity: 91,
      specialty: 'Venture Capital & Real Estate',
      colorHex: 0x34d399,
      pose: 'standing',
      speed: 1.05,
      y: MEZZANINE_Y, // ¡Planta alta Mezzanine!
      waypoints: [
        { x: 6.2, z: -5.5, wait: 5.0, emote: '☕' },
        { x: 5.6, z: -1.2, wait: 4.0, emote: '✨' },
        { x: 6.2, z: 1.8, wait: 5.0, emote: '💎' },
      ],
      currentWp: 0,
      waitTimer: 3.0,
      greetTimer: 0,
    },
    {
      id: 'npc_kenji',
      name: 'Kenji Sato',
      company: 'Shest Café & Barista VIP',
      status: 'Disponible',
      affinity: 88,
      specialty: 'Hospitalidad & Networking VIP',
      colorHex: 0xf59e0b,
      pose: 'tablet',
      speed: 0.85,
      y: 0,
      waypoints: [
        { x: 2.6, z: -3.6, wait: 5.0, emote: '☕' },
        { x: 3.6, z: -3.0, wait: 4.0, emote: '🥐' },
      ],
      currentWp: 0,
      waitTimer: 2.0,
      greetTimer: 0,
    },
  ];

  for (const npc of patrolNPCs) {
    npc.avatar = createAvatar({
      id: npc.id,
      name: npc.name,
      company: npc.company,
      status: npc.status,
      colorHex: npc.colorHex,
      pose: npc.pose,
    });
    const firstWp = npc.waypoints[0];
    npc.x = firstWp.x;
    npc.z = firstWp.z;
    npc.rot = 0;
    npc.avatar.group.position.set(npc.x, npc.y, npc.z);
    root.add(npc.avatar.group);
    interactables.push(...npc.avatar.hitTargets);
    allNpcAvatars.push(npc.avatar);
  }

  // Conserje Holográfico NEXUS AI atendiendo en mostrador de recepción
  const receptionist = createAvatar({
    id: 'npc_receptionist',
    name: 'NEXUS AI · Conserje',
    company: 'Copiloto Holográfico 24/7',
    status: 'IA Activa',
    colorHex: 0x00f0ff,
    pose: 'tablet',
  });
  receptionist.group.position.set(recCX, 0, recCZ + 0.65);
  receptionist.group.rotation.y = Math.PI;
  for (const ht of receptionist.hitTargets) {
    ht.userData.isNexusAi = true;
  }
  root.add(receptionist.group);
  interactables.push(...receptionist.hitTargets);
  allNpcAvatars.push(receptionist);

  // =========================================================================
  // 8. KIOSCO COMERCIAL INTERACTIVO 3D (VITRINA P2P & ESCROW USDT — FASE 5)
  // =========================================================================
  const kioskCX = ((BOXES.kioskCompany.minX + BOXES.kioskCompany.maxX) / 2) * S;
  const kioskCZ = ((BOXES.kioskCompany.minZ + BOXES.kioskCompany.maxZ) / 2) * S;

  const kioskBase = box(0.68, 1.18, 0.56, obsidianMat, kioskCX, 0.59, kioskCZ);
  const kioskGoldTrim = box(0.72, 0.05, 0.60, goldTrimMat, kioskCX, 1.19, kioskCZ, false, false);
  const kioskBaseGlow = new THREE.Mesh(
    new THREE.TorusGeometry(0.56, 0.022, 8, 32),
    glow(ORO_PREMIUM, 2.4)
  );
  kioskBaseGlow.rotation.x = Math.PI / 2;
  kioskBaseGlow.position.set(kioskCX, 0.03, kioskCZ);

  const kioskHoloPad = new THREE.Mesh(
    new THREE.CylinderGeometry(0.26, 0.30, 0.04, 24),
    glow(CIAN_HOLO, 2.2)
  );
  kioskHoloPad.position.set(kioskCX, 1.23, kioskCZ);

  // Vitrina Holográfica 3D con 3 productos rotatorios intercambiables
  const kioskProductGroup = new THREE.Group();
  kioskProductGroup.position.set(kioskCX, 1.66, kioskCZ);
  root.add(kioskProductGroup);

  // Producto 0: Nodo Validador Institucional PREMION (Cristal Octaédrico Oro + Anillos Cian)
  const prod0Group = new THREE.Group();
  const prod0Crystal = new THREE.Mesh(
    new THREE.OctahedronGeometry(0.24, 0),
    new THREE.MeshStandardMaterial({ color: ORO_PREMIUM, metalness: 0.95, roughness: 0.12, emissive: ORO_PREMIUM, emissiveIntensity: 0.35 })
  );
  const prod0Ring = new THREE.Mesh(
    new THREE.TorusGeometry(0.32, 0.014, 8, 32),
    glow(CIAN_HOLO, 2.4)
  );
  prod0Ring.rotation.x = Math.PI / 3;
  prod0Group.add(prod0Crystal, prod0Ring);

  // Producto 1: Bóveda Hardware Multi-Firma E2EE (Cubo Blindado Oro/Esmeralda)
  const prod1Group = new THREE.Group();
  prod1Group.visible = false;
  const prod1Cube = new THREE.Mesh(
    new THREE.BoxGeometry(0.32, 0.32, 0.32),
    new THREE.MeshStandardMaterial({ color: 0x0f172a, metalness: 0.9, roughness: 0.18 })
  );
  const prod1Wire = new THREE.Mesh(
    new THREE.BoxGeometry(0.35, 0.35, 0.35),
    new THREE.MeshBasicMaterial({ color: VERDE_ESMERALDA, wireframe: true })
  );
  prod1Group.add(prod1Cube, prod1Wire);

  // Producto 2: Suite Corporativa VIP Dedicada (Corona Toroidal Dorada)
  const prod2Group = new THREE.Group();
  prod2Group.visible = false;
  const prod2Crown = new THREE.Mesh(
    new THREE.TorusKnotGeometry(0.18, 0.045, 64, 12),
    new THREE.MeshStandardMaterial({ color: 0xffd978, metalness: 0.95, roughness: 0.1, emissive: ORO_PREMIUM, emissiveIntensity: 0.4 })
  );
  prod2Group.add(prod2Crown);

  kioskProductGroup.add(prod0Group, prod1Group, prod2Group);
  const kioskProductModels = [prod0Group, prod1Group, prod2Group];
  let currentKioskProduct = 0;

  function setKioskProduct(idx) {
    currentKioskProduct = ((idx % 3) + 3) % 3;
    kioskProductModels.forEach((m, i) => {
      m.visible = i === currentKioskProduct;
    });
    return currentKioskProduct;
  }

  const kioskSign = new THREE.Mesh(
    new THREE.PlaneGeometry(1.75, 0.48),
    new THREE.MeshBasicMaterial({
      map: canvasTexture(640, 176, (ctx, w, h) => {
        ctx.fillStyle = 'rgba(8, 10, 16, 0.92)';
        ctx.beginPath();
        ctx.roundRect(6, 6, w - 12, h - 12, 22);
        ctx.fill();
        ctx.lineWidth = 4;
        ctx.strokeStyle = '#d4af37';
        ctx.stroke();

        ctx.fillStyle = '#ffd978';
        ctx.font = '900 22px "Segoe UI", Arial, sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText('🛍️ KIOSCO COMERCIAL 3D · ESCROW', w / 2, 62);

        ctx.fillStyle = '#00f0ff';
        ctx.font = 'bold 18px "Segoe UI", Arial, sans-serif';
        ctx.fillText('ACTIVOS P2P & LICENCIAS VIP · [E / K / CLIC]', w / 2, 118);
      }),
      transparent: true,
      side: THREE.DoubleSide,
    }),
  );
  kioskSign.position.set(kioskCX, 2.32, kioskCZ);

  for (const ko of [kioskBase, kioskHoloPad, prod0Crystal, prod1Cube, prod2Crown, kioskSign]) {
    ko.userData.isKiosk = true;
    interactables.push(ko);
  }

  root.add(kioskBase, kioskGoldTrim, kioskBaseGlow, kioskHoloPad, kioskSign);

  animated.push((dt, t) => {
    kioskProductGroup.rotation.y += dt * 1.15;
    kioskProductGroup.position.y = 1.66 + Math.sin(t * 2.4) * 0.04;
    kioskSign.position.y = 2.32 + Math.sin(t * 1.9) * 0.025;
  });

  // =========================================================================
  // 9. TAPETE LUMINOSO DE SPAWN "WORDVERSE" (Cuadrante Inferior Izquierdo)
  // =========================================================================
  const spawnMatTex = canvasTexture(768, 420, (ctx, w, h) => {
    ctx.fillStyle = '#0a0a0c';
    ctx.fillRect(0, 0, w, h);

    // Marco exterior en Oro Premium WordVerse
    ctx.strokeStyle = '#d4af37';
    ctx.lineWidth = 10;
    ctx.strokeRect(14, 14, w - 28, h - 28);

    drawLogo(ctx, w / 2, 135, 80);

    ctx.fillStyle = '#ffd978';
    ctx.font = '900 68px "Segoe UI", Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('WORDVERSE', w / 2, 285);
  });

  const spawnPad = new THREE.Mesh(
    new THREE.PlaneGeometry(3.2, 1.8),
    new THREE.MeshBasicMaterial({ map: spawnMatTex }),
  );
  spawnPad.rotation.x = -Math.PI / 2;
  spawnPad.position.set(0.0, 0.025, 4.2);
  spawnPad.receiveShadow = true;
  root.add(spawnPad);

  // Anillo de luz dorado alrededor del tapete
  const padBorder = box(3.3, 0.04, 1.9, glow(ORO_PREMIUM, 2.5), 0.0, 0.03, 4.2, false, false);
  root.add(padBorder);

  // =========================================================================
  // 10. ESTELAS DE DATOS LUMINOSAS CURVAS (Flujo de Conectividad)
  // =========================================================================
  const privCX = -6.0;
  const privCZ = 1.0;

  const dataRoutes = [
    // Líneas de circuito doradas a ras de suelo (sin atravesar el aire)
    [[-5.2, 0.03, 0.0], [-2.5, 0.03, 0.0], [0, 0.03, 0], [2.4, 0.03, 1.2], [recCX, 0.03, recCZ]],
    [[privCX, 0.03, privCZ], [-2.2, 0.03, 1.5], [0, 0.03, 2.2], [0, 0.03, 3.8]],
  ];

  dataRoutes.forEach((pts, i) => {
    const curve = new THREE.CatmullRomCurve3(pts.map(([x, y, z]) => new THREE.Vector3(x, y, z)));
    const len = curve.getLength();

    const tubeTex = canvasTexture(256, 16, (ctx, w, h) => {
      const g = ctx.createLinearGradient(0, 0, w, 0);
      g.addColorStop(0, 'rgba(56,189,248,0)');
      g.addColorStop(0.7, 'rgba(125,211,252,1)');
      g.addColorStop(1, 'rgba(255,255,255,1)');
      ctx.fillStyle = g;
      ctx.fillRect(0, 0, w * 0.4, h);
    }, { repeat: true });
    tubeTex.repeat.set(len / 3.5, 1);

    const tube = new THREE.Mesh(
      new THREE.TubeGeometry(curve, 120, 0.045, 8, false),
      new THREE.MeshBasicMaterial({
        map: tubeTex,
        transparent: true,
        blending: THREE.AdditiveBlending,
        depthWrite: false,
        toneMapped: false,
        color: new THREE.Color(2, 2, 2),
      }),
    );
    root.add(tube);

    animated.push((dt) => {
      tubeTex.offset.x -= dt * (0.4 + i * 0.1);
    });
  });

  // =========================================================================
  // 11. HOTSPOTS OFICIALES (7 + CAFÉ) CON MARCADORES HOLOGRAMAS
  // =========================================================================
  const hotspotObjs = new Map();

  for (const h of hotspots) {
    const color = new THREE.Color(h.color || '#22d3ee');
    const g = new THREE.Group();
    g.position.set(h.x * S, 0, h.z * S);

    const ring = new THREE.Mesh(new THREE.TorusGeometry(0.85, 0.045, 8, 48), glow(color, 2.2));
    ring.rotation.x = Math.PI / 2;
    ring.position.y = 0.05;

    const disc = new THREE.Mesh(
      new THREE.CircleGeometry(0.85, 48),
      new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.12, depthWrite: false }),
    );
    disc.rotation.x = -Math.PI / 2;
    disc.position.y = 0.04;

    const beamTex = canvasTexture(8, 128, (ctx, w, hh) => {
      const gr = ctx.createLinearGradient(0, hh, 0, 0);
      gr.addColorStop(0, 'rgba(255,255,255,0.85)');
      gr.addColorStop(1, 'rgba(255,255,255,0)');
      ctx.fillStyle = gr;
      ctx.fillRect(0, 0, w, hh);
    });

    const beam = new THREE.Mesh(
      new THREE.CylinderGeometry(0.7, 0.85, 3.6, 24, 1, true),
      new THREE.MeshBasicMaterial({
        map: beamTex,
        color: color.clone().multiplyScalar(1.5),
        transparent: true,
        opacity: 0.45,
        blending: THREE.AdditiveBlending,
        depthWrite: false,
        side: THREE.DoubleSide,
        toneMapped: false,
      }),
    );
    beam.position.y = 1.8;

    const label = new THREE.Sprite(
      new THREE.SpriteMaterial({
        map: hotspotLabelTexture({
          code: h.code,
          title: h.title,
          subtitle: h.subtitle,
          color: '#' + color.getHexString(),
        }),
        transparent: true,
        depthWrite: false,
      }),
    );
    label.scale.set(1.75, 0.68, 1);
    label.position.y = 3.15;
    label.renderOrder = 9;

    for (const o of [ring, disc, beam, label]) o.userData.hotspot = h;
    g.add(ring, disc, beam, label);
    root.add(g);
    interactables.push(ring, disc, beam, label);
    hotspotObjs.set(h.kind, { group: g, ring, beam, label, disc, near: 0 });
  }

  animated.push((dt, t) => {
    for (const o of hotspotObjs.values()) {
      o.near += ((o.target || 0) - o.near) * Math.min(1, dt * 8);
      o.ring.rotation.z = t * 0.6;
      o.ring.scale.setScalar(1 + o.near * 0.18 + Math.sin(t * 2.2) * 0.03);
      o.beam.material.opacity = 0.28 + o.near * 0.42;
      o.label.position.y = 3.15 + Math.sin(t * 1.6) * 0.06 + o.near * 0.18;
      const lScale = 1 + o.near * 0.10;
      o.label.scale.set(1.75 * lScale, 0.68 * lScale, 1);
    }
  });

  return {
    root,
    interactables,
    elevator,
    update(dt, t, player) {
      elevator.update(dt);
      for (const f of animated) f(dt, t);

      const inBoard = player ? player.x > 1.8 : false;
      // Culling de Zona (Fase 5): ocultar geometría interna de Boardroom si el usuario está lejos en el Atrio
      boardroomRoot.visible = player ? player.x > 1.15 : true;

      // Smart LOD 2.0: ocultar carteles flotantes a más de 5.5m y pausar patrullaje del Atrio si el jugador está en el Boardroom
      if (player) {
        const px = player.x * S;
        const pz = player.z * S;
        for (const av of allNpcAvatars) {
          if (av && av.plate) {
            const d = Math.hypot(px - av.group.position.x, pz - av.group.position.z);
            av.plate.visible = d <= 5.5;
          }
        }
      }

      if (inBoard) return;

      // Actualizar IA de patrullaje de NPCs ejecutivos en el Atrio / Mezzanine
      for (const npc of patrolNPCs) {
        if (npc.greetTimer > 0) npc.greetTimer -= dt;

        const playerDist = player ? Math.hypot(npc.x - player.x * S, npc.z - player.z * S) : 999;
        const sameFloor = player ? Math.abs(npc.y - (player.y || 0)) < 1.8 : false;

        // Si el jugador está cerca en el mismo piso: detenerse, orientar la mirada y saludar
        if (player && playerDist < 2.3 && sameFloor) {
          const lookAngle = Math.atan2((player.x * S) - npc.x, (player.z * S) - npc.z);
          let dRot = lookAngle - npc.rot;
          dRot = Math.atan2(Math.sin(dRot), Math.cos(dRot));
          npc.rot += dRot * Math.min(1, dt * 6);
          npc.avatar.group.rotation.y = npc.rot;
          npc.avatar.update(dt, t, 0);

          if (npc.greetTimer <= 0) {
            npc.avatar.showEmote('👋', t);
            npc.greetTimer = 8.5;
          }
          continue;
        }

        // Navegación fluida por waypoints
        const wp = npc.waypoints[npc.currentWp];
        const dx = wp.x - npc.x;
        const dz = wp.z - npc.z;
        const distToWp = Math.hypot(dx, dz);

        if (distToWp > 0.14 && npc.waitTimer <= 0) {
          const targetRot = Math.atan2(dx, dz);
          let dRot = targetRot - npc.rot;
          dRot = Math.atan2(Math.sin(dRot), Math.cos(dRot));
          npc.rot += dRot * Math.min(1, dt * 7);

          const moveStep = Math.min(distToWp, npc.speed * dt);
          npc.x += Math.sin(npc.rot) * moveStep;
          npc.z += Math.cos(npc.rot) * moveStep;

          npc.avatar.group.position.set(npc.x, npc.y, npc.z);
          npc.avatar.group.rotation.y = npc.rot;
          npc.avatar.update(dt, t, 1.0); // Animación de paso ejecutivo
        } else {
          if (npc.waitTimer <= 0) {
            npc.waitTimer = wp.wait || 4.0;
            if (wp.emote) npc.avatar.showEmote(wp.emote, t);
          } else {
            npc.waitTimer -= dt;
            if (npc.waitTimer <= 0) {
              npc.currentWp = (npc.currentWp + 1) % npc.waypoints.length;
            }
          }
          npc.avatar.update(dt, t, 0); // Idle breathing
        }
      }

      // Recepcionista orienta la mirada al jugador si está frente al mostrador
      if (player) {
        const distToRec = Math.hypot(player.x * S - recCX, player.z * S - (recCZ + 0.65));
        if (distToRec < 3.2 && (player.y || 0) < 1.5) {
          const recAngle = Math.atan2(player.x * S - recCX, player.z * S - (recCZ + 0.65));
          receptionist.group.rotation.y = recAngle;
          receptionist.update(dt, t, 0);
        } else {
          receptionist.group.rotation.y = Math.PI;
          receptionist.update(dt, t, 0);
        }
      }
    },
    setNearHotspot(kind) {
      for (const [k, o] of hotspotObjs) o.target = k === kind ? 1 : 0;
    },
    setAccent(hex) {
      coreLight.color.set(hex);
    },
    setBoardroomSlide(idx) {
      return setBoardroomSlide(idx);
    },
    nextBoardroomSlide() {
      return nextBoardroomSlide();
    },
    prevBoardroomSlide() {
      return prevBoardroomSlide();
    },
    getBoardroomSlide() {
      return currentBoardroomSlide;
    },
    setNexusAiSpeaking(active) {
      nexusAiSpeaking = !!active;
      if (nexusAiSpeaking) {
        receptionist.showEmote('🤖', performance.now() / 1000);
        if (receptionist.playGesture) receptionist.playGesture('wave');
      }
    },
    setKioskProduct(idx) {
      return setKioskProduct(idx);
    },
    getKioskProduct() {
      return currentKioskProduct;
    },
    getNearestAffinityMatch(playerX, playerZ, playerY = 0) {
      if (playerX > 1.8) {
        return {
          id: 'boardroom_syndicate',
          name: 'Andrés Morales',
          company: 'Andes Capital · Socio Fundador',
          affinity: 98,
          specialty: 'Ronda Sindicada 2026 & Multi-Sig',
          dist: 1.4,
          x: 2.6,
          z: -0.25,
        };
      }
      let best = null;
      let bestDist = Infinity;
      const px = playerX * S;
      const pz = playerZ * S;
      for (const npc of patrolNPCs) {
        if (Math.abs(npc.y - playerY) > 2.0) continue;
        const d = Math.hypot(px - npc.x, pz - npc.z);
        if (d < bestDist) {
          bestDist = d;
          best = {
            id: npc.id,
            name: npc.name,
            company: npc.company,
            affinity: npc.affinity,
            specialty: npc.specialty,
            dist: Number(d.toFixed(1)),
            x: npc.x / S,
            z: npc.z / S,
            avatar: npc.avatar,
          };
        }
      }
      return best;
    },
  };
}
