// Física 2D del Hub (plano XZ, coordenadas NORMALIZADAS como en RoomPhysicsController.dart).
// Módulo puro (sin DOM ni Three.js) para poder probarlo con `node test/physics.test.mjs`.

export const WORLD_SCALE = 10; // 1.0 normalizado = 10 metros
export const BOUND = 0.90; // muros perimetrales ampliados para mayor amplitud espacial
export const TABLE_R = 0.19; // plataforma holográfica central
export const PLAYER_R = 0.025;
export const SPAWN = { x: 0.0, z: 0.32 };
export const HOTSPOT_TRIGGER_R = 0.18;

export const MEZZANINE_Y = 4.2; // Altura de planta alta en metros

/**
 * Coordenadas de las Escaleras Monumentales (normalizadas):
 * Conectan la planta baja (z = -0.08, y = 0) con el Mezzanine (z = -0.46, y = 4.2).
 */
export const STAIRS = {
  minX: 0.38,
  maxX: 0.58,
  minZ: -0.48,
  maxZ: -0.06,
};

/**
 * Coordenadas del Ascensor Panorámico de Cristal (normalizadas):
 * Ubicado en el flanco oeste de alta visibilidad (x = -0.45, z = 0.08)
 * Freestanding, completamente visible desde Atrio y Mezzanine, separado de escaleras.
 */
export const ELEVATOR = {
  x: -0.62,
  z: 0.0,
  radius: 0.10,
  doorZ: 0.10, // Frente de la puerta orientado hacia el atrio abierto
};

/**
 * Puestos de Asiento Interactivos (Sofás Lounge VIP y Sillas Ejecutivas).
 * Coordenadas exactas alineadas al radio 3.05m de las sillas libres de The Boardroom
 * y a los sofás del Lobby y Mezzanine.
 */
export const SEATS = [
  { id: 'sofa_left_1', x: -0.46, z: 0.44, y: 0, rot: Math.PI * 0.25, name: 'Sillón Lounge Lobby Oeste' },
  { id: 'sofa_right_1', x: 0.46, z: 0.28, y: 0, rot: -Math.PI * 0.25, name: 'Sillón Lounge Lobby Este' },
  { id: 'mezz_couch_1', x: 0.64, z: -0.62, y: MEZZANINE_Y, rot: Math.PI, name: 'Sillón Cuero Mezzanine Norte' },
  { id: 'mezz_couch_2', x: 0.64, z: 0.22, y: MEZZANINE_Y, rot: 0, name: 'Sillón Cuero Mezzanine Sur' },
  { id: 'board_seat_host', x: 2.60, z: 0.305, y: 0, rot: Math.PI, name: 'Sillón Presidencial Host (Boardroom)' },
  { id: 'board_seat_west', x: 2.295, z: 0.0, y: 0, rot: Math.PI / 2, name: 'Silla Directiva Oeste (Boardroom)' },
  { id: 'board_seat_se', x: 2.816, z: 0.216, y: 0, rot: -Math.PI * 0.75, name: 'Silla Directiva Sureste (Boardroom)' },
  { id: 'board_seat_ne', x: 2.816, z: -0.216, y: 0, rot: -Math.PI * 0.25, name: 'Silla Directiva Noreste (Boardroom)' },
];

export const PILLARS = [
  [-0.82, -0.82],
  [0.82, -0.82],
  [0.82, 0.82],
  [-0.82, 0.82],
];
export const PILLAR_R = 0.08;

/**
 * Coordenadas de la Sala Privada (The Boardroom) en coordenadas normalizadas.
 * Situada en el ala VIP adyacente conectada por el portal interactivo.
 */
export const BOARDROOM_CENTER = { x: 2.6, z: 0.0 };
export const BOARDROOM_RADIUS = 0.72;
export const BOARDROOM_TABLE_R = 0.24;

export function isInBoardroom(x) {
  return x > 1.8;
}

export function isNearPrivatePortal(x, z) {
  return Math.hypot(x - 0.62, z - (-0.80)) < 0.16;
}

export function isNearBoardroomExit(x, z) {
  return Math.hypot(x - (BOARDROOM_CENTER.x - 0.48), z - 0.42) < 0.17;
}

/**
 * Volúmenes rectangulares con colisión en Planta Baja (AABB en coordenadas normalizadas).
 */
export const BOXES = {
  receptionDesk: { minX: 0.26, maxX: 0.68, minZ: 0.22, maxZ: 0.44 },
  kioskCompany: { minX: -0.38, maxX: -0.26, minZ: 0.08, maxZ: 0.24 },
};

/**
 * Determina si el jugador está frente al mostrador de recepción donde opera el Conserje Holográfico Nexus AI.
 */
export function isNearReceptionDesk(x, z, y = 0) {
  if (y >= 1.5) return false;
  return x >= 0.22 && x <= 0.72 && z >= 0.06 && z <= 0.52;
}

/**
 * Determina si el jugador está junto al Kiosco Comercial Interactivo 3D (Stand P2P & Escrow).
 */
export function isNearKiosk(x, z, y = 0) {
  if (y >= 1.5) return false;
  const cx = (BOXES.kioskCompany.minX + BOXES.kioskCompany.maxX) / 2;
  const cz = (BOXES.kioskCompany.minZ + BOXES.kioskCompany.maxZ) / 2;
  return Math.hypot(x - cx, z - cz) < 0.22;
}

function pushOutOfCircle(p, cx, cz, r) {
  const dx = p.x - cx;
  const dz = p.z - cz;
  const d = Math.hypot(dx, dz);
  if (d >= r) return false;
  if (d < 1e-6) {
    p.x = cx;
    p.z = cz + r;
    return true;
  }
  p.x = cx + (dx / d) * r;
  p.z = cz + (dz / d) * r;
  return true;
}

function pushOutOfBox(p, b, r) {
  const cx = Math.min(Math.max(p.x, b.minX), b.maxX);
  const cz = Math.min(Math.max(p.z, b.minZ), b.maxZ);
  const dx = p.x - cx;
  const dz = p.z - cz;
  const d = Math.hypot(dx, dz);
  if (d >= r) return false;
  if (d > 0.00001) {
    p.x = cx + (dx / d) * r;
    p.z = cz + (dz / d) * r;
    return true;
  }
  const left = p.x - b.minX;
  const right = b.maxX - p.x;
  const top = p.z - b.minZ;
  const bottom = b.maxZ - p.z;
  const m = Math.min(left, right, top, bottom);
  if (m === left) p.x = b.minX - r;
  else if (m === right) p.x = b.maxX + r;
  else if (m === top) p.z = b.minZ - r;
  else p.z = b.maxZ + r;
  return true;
}

export function isInStairs(x, z) {
  // Escalera Monumental Dorada en su espacio propio del Ala Este
  if (x >= STAIRS.minX && x <= STAIRS.maxX && z >= STAIRS.minZ && z <= STAIRS.maxZ) return true;
  return false;
}

export function getStairHeight(z) {
  const t = (STAIRS.maxZ - z) / (STAIRS.maxZ - STAIRS.minZ);
  return Math.min(Math.max(t * MEZZANINE_Y, 0), MEZZANINE_Y);
}

export function isNearElevator(x, z, maxDist = 0.22) {
  return Math.hypot(x - ELEVATOR.x, z - ELEVATOR.doorZ) <= maxDist;
}

export function isInsideElevator(x, z) {
  return Math.abs(x - ELEVATOR.x) <= 0.095 && (z >= ELEVATOR.z - 0.095 && z <= ELEVATOR.doorZ + 0.02);
}

export function resolve(x, z, y = 0) {
  const p = { x, z };
  let collided = false;
  const lim = BOUND - PLAYER_R;

  // Si está dentro de la cabina del ascensor, permitir movimiento libre en su interior y salida frontal
  if (isInsideElevator(p.x, p.z)) {
    p.x = Math.max(ELEVATOR.x - 0.085, Math.min(ELEVATOR.x + 0.085, p.x));
    p.z = Math.max(ELEVATOR.z - 0.085, p.z);
    return { x: p.x, z: p.z, collided: false };
  }

  // Lógica de colisión en The Boardroom (Sala Privada VIP)
  if (p.x > 1.8 && p.x < 3.8) {
    if (pushOutOfCircle(p, BOARDROOM_CENTER.x, BOARDROOM_CENTER.z, BOARDROOM_TABLE_R + PLAYER_R)) {
      collided = true;
    }
    const dFromCenter = Math.hypot(p.x - BOARDROOM_CENTER.x, p.z - BOARDROOM_CENTER.z);
    const maxR = BOARDROOM_RADIUS - PLAYER_R;
    if (dFromCenter > maxR) {
      collided = true;
      p.x = BOARDROOM_CENTER.x + ((p.x - BOARDROOM_CENTER.x) / dFromCenter) * maxR;
      p.z = BOARDROOM_CENTER.z + ((p.z - BOARDROOM_CENTER.z) / dFromCenter) * maxR;
    }
    return { x: p.x, z: p.z, collided };
  }

  // Lógica de colisión en Planta Alta (Mezzanine)
  if (y >= 3.0) {
    // Si está en la escalera o aproximándose al ascensor superior, mantener libertad de paso
    if (isInStairs(p.x, p.z) || isNearElevator(p.x, p.z)) {
      if (p.x < -lim) { p.x = -lim; collided = true; }
      if (p.x > lim) { p.x = lim; collided = true; }
      if (p.z < -lim) { p.z = -lim; collided = true; }
      if (p.z > lim) { p.z = lim; collided = true; }
      return { x: p.x, z: p.z, collided };
    }

    // Barandilla perimetral interna hacia el atrio central
    // El hueco del atrio va de X: -0.46 a 0.56, y Z > -0.44
    const inHoleX = p.x > -0.46 && p.x < 0.56;
    const inHoleZ = p.z > -0.44;
    if (inHoleX && inHoleZ) {
      // Excepciones: entrada a las escaleras y al ascensor
      const isStairEntry = p.x >= STAIRS.minX && p.x <= STAIRS.maxX && p.z <= STAIRS.minZ + 0.04;
      const isElevEntry = Math.hypot(p.x - ELEVATOR.x, p.z - ELEVATOR.doorZ) <= 0.16;
      if (!isStairEntry && !isElevEntry) {
        collided = true;
        const dNorth = Math.abs(p.z - (-0.44));
        const dWest = Math.abs(p.x - (-0.46));
        const dEast = Math.abs(p.x - 0.56);
        const minD = Math.min(dNorth, dWest, dEast);
        if (minD === dNorth) p.z = -0.44 - PLAYER_R;
        else if (minD === dWest) p.x = -0.46 - PLAYER_R;
        else p.x = 0.56 + PLAYER_R;
      }
    }

    if (p.x < -lim) { p.x = -lim; collided = true; }
    if (p.x > lim) { p.x = lim; collided = true; }
    if (p.z < -lim) { p.z = -lim; collided = true; }
    if (p.z > lim) { p.z = lim; collided = true; }
    return { x: p.x, z: p.z, collided };
  }

  // Lógica de colisión en Planta Baja (Nivel 1)
  for (let i = 0; i < 3; i++) {
    if (pushOutOfCircle(p, 0, 0, TABLE_R + PLAYER_R)) collided = true;
    for (const [px, pz] of PILLARS) {
      if (pushOutOfCircle(p, px, pz, PILLAR_R + PLAYER_R)) collided = true;
    }
    for (const b of Object.values(BOXES)) {
      if (pushOutOfBox(p, b, PLAYER_R)) collided = true;
    }
    if (p.x < -lim) { p.x = -lim; collided = true; }
    if (p.x > lim) { p.x = lim; collided = true; }
    if (p.z < -lim) { p.z = -lim; collided = true; }
    if (p.z > lim) { p.z = lim; collided = true; }
  }
  return { x: p.x, z: p.z, collided };
}

export function nearestHotspot(x, z, hotspots, radius = HOTSPOT_TRIGGER_R) {
  let best = null;
  let bestD = radius;
  for (const h of hotspots) {
    const d = Math.hypot(x - h.x, z - h.z);
    if (d <= bestD) {
      best = h;
      bestD = d;
    }
  }
  return best;
}

export function cameraRelativeMove(camYaw, fwd, strafe) {
  const fx = -Math.sin(camYaw);
  const fz = -Math.cos(camYaw);
  const rx = Math.cos(camYaw);
  const rz = -Math.sin(camYaw);
  let dx = fx * fwd + rx * strafe;
  let dz = fz * fwd + rz * strafe;
  const len = Math.hypot(dx, dz);
  if (len > 1) {
    dx /= len;
    dz /= len;
  }
  return { dx, dz, len: Math.min(1, len) };
}
