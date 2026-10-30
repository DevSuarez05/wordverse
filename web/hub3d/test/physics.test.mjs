// Ejecutar: node web/hub3d/test/physics.test.mjs
import assert from 'node:assert/strict';
import {
  BOUND, BOXES, PLAYER_R, SPAWN, TABLE_R, cameraRelativeMove, nearestHotspot, resolve,
} from '../src/physics.js';

// 1. El spawn es transitable
let r = resolve(SPAWN.x, SPAWN.z);
assert.equal(r.collided, false, 'spawn libre');

// 2. Muros perimetrales
r = resolve(5, 5);
assert.ok(Math.abs(r.x) <= BOUND && Math.abs(r.z) <= BOUND);
assert.equal(r.collided, true);

// 3. Mesa central: nadie puede quedar dentro
for (const [x, z] of [[0, 0], [0.05, 0.02], [-0.1, 0.1]]) {
  const p = resolve(x, z);
  assert.ok(Math.hypot(p.x, p.z) >= TABLE_R + PLAYER_R - 1e-6, 'fuera de la mesa');
}

// 4. Caminando hacia cada caja desde un lado libre, nunca se entra
for (const [name, b] of Object.entries(BOXES)) {
  const cx = (b.minX + b.maxX) / 2;
  const cz = (b.minZ + b.maxZ) / 2;
  const starts = [[cx, b.maxZ + 0.1], [b.minX - 0.1, cz], [b.maxX + 0.1, cz]];
  for (const [sx, sz] of starts) {
    let p = resolve(sx, sz);
    if (p.x > b.minX && p.x < b.maxX && p.z > b.minZ && p.z < b.maxZ) continue; // lado pegado al muro
    for (let i = 0; i < 300; i++) {
      const dx = cx - p.x, dz = cz - p.z;
      const len = Math.hypot(dx, dz) || 1;
      p = resolve(p.x + (dx / len) * 0.01, p.z + (dz / len) * 0.01);
      const inside = p.x > b.minX && p.x < b.maxX && p.z > b.minZ && p.z < b.maxZ;
      assert.equal(inside, false, 'dentro de ' + name);
    }
  }
}

// 5. Los 7 hotspots oficiales son alcanzables (su posición no queda bloqueada)
const hotspots = [
  { name: 'networking', x: -0.6, z: -0.45 },
  { name: 'createMeeting', x: 0.0, z: -0.65 },
  { name: 'qr', x: 0.6, z: -0.45 },
  { name: 'p2p', x: -0.68, z: 0.2 },
  { name: 'escrow', x: 0.68, z: 0.2 },
  { name: 'myProfile', x: -0.45, z: 0.68 },
  { name: 'exit', x: 0.45, z: 0.68 },
];
for (const h of hotspots) {
  const p = resolve(h.x, h.z);
  const near = nearestHotspot(p.x, p.z, hotspots);
  assert.equal(near?.name, h.name, `hotspot ${h.name} alcanzable`);
}

// 6. Movimiento relativo a cámara
let m = cameraRelativeMove(0, 1, 0);
assert.ok(Math.abs(m.dx) < 1e-9 && Math.abs(m.dz + 1) < 1e-9, 'adelante = -z con yaw 0');
m = cameraRelativeMove(0, 0, 1);
assert.ok(Math.abs(m.dx - 1) < 1e-9, 'derecha = +x con yaw 0');
m = cameraRelativeMove(0, 1, 1);
assert.ok(m.len <= 1.0000001, 'diagonal normalizada');

// 7. Escaleras y Mezzanine
import {
  MEZZANINE_Y, STAIRS, isInStairs, getStairHeight, isNearElevator, isInsideElevator,
} from '../src/physics.js';
assert.equal(isInStairs(0.48, -0.25), true, 'dentro de escalera');
assert.equal(isInStairs(0.0, 0.0), false, 'fuera de escalera');
assert.ok(Math.abs(getStairHeight(STAIRS.maxZ)) < 1e-5, 'altura 0 al pie de escalera');
assert.ok(Math.abs(getStairHeight(STAIRS.minZ) - MEZZANINE_Y) < 1e-5, 'altura 4.2 arriba de escalera');

// 8. Colisión en Mezzanine: no caer al atrio
let mezWalk = resolve(0.0, -0.30, MEZZANINE_Y);
assert.ok(mezWalk.z <= -0.44, 'retenido por la barandilla de vidrio del mezzanine');

// 9. Ascensor interactivo, Recepción Nexus AI y Kiosco Comercial 3D
import { ELEVATOR, isNearReceptionDesk, isNearKiosk } from '../src/physics.js';
assert.equal(isNearElevator(ELEVATOR.x, ELEVATOR.doorZ), true, 'cerca de puerta de ascensor');
assert.equal(isInsideElevator(ELEVATOR.x, ELEVATOR.z), true, 'dentro de cabina');
assert.equal(isNearReceptionDesk(0.47, 0.16, 0), true, 'frente al mostrador de recepción Nexus AI');
assert.equal(isNearReceptionDesk(0.47, 0.16, MEZZANINE_Y), false, 'en mezzanine no activa recepción de planta baja');
assert.equal(isNearReceptionDesk(-0.5, -0.5, 0), false, 'lejos de recepción');
assert.equal(isNearKiosk(-0.32, 0.28, 0), true, 'frente al Kiosco Comercial 3D');
assert.equal(isNearKiosk(-0.32, 0.28, MEZZANINE_Y), false, 'en mezzanine no activa Kiosco de planta baja');
assert.equal(isNearKiosk(0.5, 0.5, 0), false, 'lejos del Kiosco');

// 10. Sala Privada VIP (Boardroom): asientos fuera de la mesa y retorno al portal sin rebote
import {
  BOARDROOM_CENTER, BOARDROOM_TABLE_R, SEATS, isNearBoardroomExit, isNearPrivatePortal,
} from '../src/physics.js';
for (const seat of SEATS.filter((s) => s.id.startsWith('board_seat'))) {
  const distFromTable = Math.hypot(seat.x - BOARDROOM_CENTER.x, seat.z - BOARDROOM_CENTER.z);
  assert.ok(distFromTable > BOARDROOM_TABLE_R + 0.04, `asiento ${seat.id} fuera del borde de la mesa`);
}
const exitPose = resolve(0.62, -0.56, 0);
assert.equal(exitPose.collided, false, 'punto de retorno frente al portal privado está libre de obstáculos');
assert.equal(isNearPrivatePortal(exitPose.x, exitPose.z), false, 'punto de retorno no re-dispara entrada a Sala Privada');
assert.equal(isNearBoardroomExit(2.12, 0.42), true, 'arco de salida de Sala Privada detectado');

console.log('physics.test.mjs: OK');
