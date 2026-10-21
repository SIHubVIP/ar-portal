(() => {
  "use strict";
  const $ = (id) => document.getElementById(id);
  const canvas = $("game");
  if (!window.THREE) {
    $("startScreen").querySelector("p").textContent = "Не удалось загрузить 3D-движок. Проверь интернет и обнови страницу.";
    return;
  }

  // ================================================================== constants
  const ROOF_HALF = 4.0;
  const GRAV = 24;
  const CP_EVERY = 400;
  const TILT_MAX = 0.62;
  const P = window.TowerProfile;
  const ITEM_TYPES = [
    { id: "crate", name: "Ящик", value: 10, h: 0.62 },
    { id: "chest", name: "Сундук", value: 40, h: 0.62 },
    { id: "shield", name: "Щит", value: 20, h: 0.22 },
    { id: "lamp", name: "Лампа", value: 15, h: 0.78 },
    { id: "potion", name: "Зелье", value: 25, h: 0.62 },
    { id: "cactus", name: "Кактус", value: 15, h: 0.8 },
    { id: "pan", name: "Сковорода", value: 10, h: 0.18 },
    { id: "duck", name: "Уточка", value: 30, h: 0.58 },
    { id: "rocket", name: "Ракета", value: 35, h: 0.9 },
    { id: "tv", name: "Телевизор", value: 30, h: 0.58 },
    { id: "gem", name: "Кристалл", value: 60, h: 0.55, tag: "редкость" },
    { id: "balloon", name: "Шарик", value: 15, h: 0.75, tag: "башня легче" },
    { id: "brick", name: "Кирпич", value: 50, h: 0.3, tag: "тяжёлый" },
    { id: "magnet", name: "Магнит", value: 25, h: 0.45, tag: "притягивает вещи" },
  ];
  const TYPE = Object.fromEntries(ITEM_TYPES.map((t) => [t.id, t]));
  const AD_TEXTS = [["ЛАПША 24/7", "#ff5d7a"], ["КИНО", "#7af0ff"], ["СУПЕР ПИЦЦА", "#ffc65c"], ["ДИСКО", "#c38bff"],
                    ["ХОТ-ДОГИ", "#2ed38f"], ["КАРАОКЕ", "#ff8ad8"], ["РЕМОНТ ДРОНОВ", "#7af0ff"], ["ПЕЛЬМЕНИ", "#ffc65c"]];

  // ================================================================== audio
  const Audio = (() => {
    let ctx = null, master, music, sfx, noiseBuf, nextTime = 0, step = 0, timer = null;
    let musicOn = P.settings().music, sfxOn = P.settings().sfx;
    const BPM = 132;
    const bassLine = [45, 45, 57, 45, 48, 48, 60, 48, 43, 43, 55, 43, 40, 40, 52, 47];
    function init() {
      if (ctx) { if (ctx.state === "suspended") ctx.resume(); return; }
      const AC = window.AudioContext || window.webkitAudioContext;
      if (!AC) return;
      ctx = new AC();
      master = ctx.createGain(); master.gain.value = 0.8; master.connect(ctx.destination);
      music = ctx.createGain(); music.gain.value = musicOn ? 0.42 : 0; music.connect(master);
      sfx = ctx.createGain(); sfx.gain.value = sfxOn ? 0.7 : 0; sfx.connect(master);
      noiseBuf = ctx.createBuffer(1, ctx.sampleRate, ctx.sampleRate);
      const d = noiseBuf.getChannelData(0);
      for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
    }
    const mtof = (m) => 440 * Math.pow(2, (m - 69) / 12);
    function env(g, t, a, peak, dcy) { g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(peak, t + a); g.gain.exponentialRampToValueAtTime(0.0001, t + a + dcy); }
    function osc(type, f0, f1, t, dur, vol, dest) {
      const o = ctx.createOscillator(), g = ctx.createGain();
      o.type = type; o.frequency.setValueAtTime(f0, t);
      if (f1) o.frequency.exponentialRampToValueAtTime(f1, t + dur);
      env(g, t, 0.005, vol, dur); o.connect(g); g.connect(dest || sfx); o.start(t); o.stop(t + dur + 0.05);
    }
    function noise(t, dur, vol, freq, q, type, dest) {
      const s = ctx.createBufferSource(); s.buffer = noiseBuf;
      const f = ctx.createBiquadFilter(); f.type = type || "bandpass"; f.frequency.value = freq; f.Q.value = q || 1;
      const g = ctx.createGain(); env(g, t, 0.003, vol, dur);
      s.connect(f); f.connect(g); g.connect(dest || sfx); s.start(t); s.stop(t + dur + 0.05);
    }
    function schedule() {
      const spb = 60 / BPM / 4;
      while (nextTime < ctx.currentTime + 0.12) {
        const t = nextTime, s = step % 16;
        if (s % 4 === 0) { osc("sine", 150, 45, t, 0.22, 0.9, music); }
        if (s === 4 || s === 12) noise(t, 0.16, 0.5, 1800, 0.8, "bandpass", music);
        if (s % 2 === 1) noise(t, 0.04, 0.22, 8000, 0.7, "highpass", music);
        const n = bassLine[s];
        if (s % 2 === 0 || s === 7) {
          const o = ctx.createOscillator(), f = ctx.createBiquadFilter(), g = ctx.createGain();
          o.type = "sawtooth"; o.frequency.value = mtof(n);
          f.type = "lowpass"; f.frequency.setValueAtTime(900, t); f.frequency.exponentialRampToValueAtTime(180, t + 0.18);
          env(g, t, 0.005, 0.32, 0.2); o.connect(f); f.connect(g); g.connect(music); o.start(t); o.stop(t + 0.3);
        }
        if (step % 64 === 32 || step % 64 === 48) osc("triangle", mtof(n + 24), 0, t, 0.25, 0.12, music);
        nextTime += spb; step++;
      }
    }
    return {
      start() { init(); if (!ctx) return; if (!timer) { nextTime = ctx.currentTime + 0.05; timer = setInterval(schedule, 25); } },
      stopMusic() { if (timer) { clearInterval(timer); timer = null; } },
      setMusic(on) { musicOn = on; P.setSetting("music", on); if (music) music.gain.value = on ? 0.42 : 0; },
      setSfx(on) { sfxOn = on; P.setSetting("sfx", on); if (sfx) sfx.gain.value = on ? 0.7 : 0; },
      musicOn: () => musicOn,
      play(name, x = 1) {
        if (!ctx || !sfxOn) return;
        const t = ctx.currentTime;
        switch (name) {
          case "jump": osc("square", 260, 620, t, 0.14, 0.18); break;
          case "pickup": { const b = 72 + Math.min(12, x) ; osc("sine", mtof(b), 0, t, 0.08, 0.35); osc("sine", mtof(b + 7), 0, t + 0.06, 0.1, 0.3); break; }
          case "drop": osc("sawtooth", 300, 70, t, 0.35, 0.25); noise(t, 0.2, 0.4, 300, 1); break;
          case "bank": [0, 4, 7, 12].forEach((k, i) => osc("triangle", mtof(72 + k), 0, t + i * 0.07, 0.25, 0.32)); noise(t, 0.6, 0.15, 6000, 0.5, "highpass"); break;
          case "laser": osc("sawtooth", 400, 1600, t, 0.7, 0.08); break;
          case "bolt": osc("square", 1200, 200, t, 0.18, 0.15); break;
          case "stumble": osc("sine", 120, 40, t, 0.3, 0.6); noise(t, 0.15, 0.3, 500, 1); break;
          case "dash": noise(t, 0.35, 0.5, 900, 0.6, "bandpass"); osc("sawtooth", 90, 260, t, 0.3, 0.12); break;
          case "smash": noise(t, 0.3, 0.7, 400, 0.7); osc("square", 180, 50, t, 0.25, 0.25); break;
          case "land": noise(t, 0.08, 0.3, 250, 1); break;
          case "near": osc("sine", 900, 1400, t, 0.12, 0.2); break;
          case "over": [0, -3, -7, -12].forEach((k, i) => osc("triangle", mtof(64 + k), 0, t + i * 0.12, 0.3, 0.3)); break;
        }
      },
    };
  })();
  const buzz = (ms) => { if (!P.settings().vibro) return; try { navigator.vibrate && navigator.vibrate(ms); } catch (e) {} };

  // ================================================================== renderer / scene
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: "high-performance" });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.75));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  const scene = new THREE.Scene();
  const FOG = new THREE.Color(0xd8788a);
  scene.fog = new THREE.Fog(FOG, 28, 150);

  function canvasTex(w, h, draw) {
    const c = document.createElement("canvas"); c.width = w; c.height = h;
    draw(c.getContext("2d"), w, h);
    const t = new THREE.CanvasTexture(c);
    return t;
  }
  scene.background = canvasTex(4, 256, (g) => {
    const gr = g.createLinearGradient(0, 0, 0, 256);
    gr.addColorStop(0, "#2b1650"); gr.addColorStop(0.42, "#9a4686"); gr.addColorStop(0.72, "#ff8f6a"); gr.addColorStop(1, "#ffd28a");
    g.fillStyle = gr; g.fillRect(0, 0, 4, 256);
  });
  const glowTex = canvasTex(128, 128, (g) => {
    const gr = g.createRadialGradient(64, 64, 0, 64, 64, 64);
    gr.addColorStop(0, "rgba(255,255,255,1)"); gr.addColorStop(0.35, "rgba(255,255,255,.45)"); gr.addColorStop(1, "rgba(255,255,255,0)");
    g.fillStyle = gr; g.fillRect(0, 0, 128, 128);
  });
  const cloudTex = canvasTex(256, 128, (g) => {
    for (let i = 0; i < 14; i++) {
      const x = 40 + Math.random() * 176, y = 50 + Math.random() * 40, r = 20 + Math.random() * 30;
      const gr = g.createRadialGradient(x, y, 0, x, y, r);
      gr.addColorStop(0, "rgba(255,210,200,.55)"); gr.addColorStop(1, "rgba(255,210,200,0)");
      g.fillStyle = gr; g.fillRect(0, 0, 256, 128);
    }
  });

  const camera = new THREE.PerspectiveCamera(64, 1, 0.1, 420);
  scene.add(new THREE.HemisphereLight(0xffd6b0, 0x553070, 0.75));
  const sunLight = new THREE.DirectionalLight(0xffb27a, 1.05);
  sunLight.castShadow = true;
  sunLight.shadow.mapSize.set(1024, 1024);
  Object.assign(sunLight.shadow.camera, { left: -9, right: 9, top: 12, bottom: -9, near: 1, far: 45 });
  sunLight.shadow.bias = -0.0015;
  scene.add(sunLight); scene.add(sunLight.target);
  function applyQuality(q) {
    const dpr = window.devicePixelRatio || 1;
    renderer.setPixelRatio(Math.min(dpr, q === "high" ? 1.75 : q === "mid" ? 1.3 : 1));
    const shadows = q !== "low";
    if (renderer.shadowMap.enabled !== shadows) {
      renderer.shadowMap.enabled = shadows; sunLight.castShadow = shadows;
      scene.traverse((o) => { if (o.material) (Array.isArray(o.material) ? o.material : [o.material]).forEach((m) => (m.needsUpdate = true)); });
    }
    const size = q === "high" ? 1024 : 512;
    if (sunLight.shadow.mapSize.x !== size) {
      sunLight.shadow.mapSize.set(size, size);
      if (sunLight.shadow.map) { sunLight.shadow.map.dispose(); sunLight.shadow.map = null; }
    }
    if (typeof resize === "function") resize();
  }

  const sunMat = new THREE.SpriteMaterial({ map: glowTex, color: 0xffd98a, fog: false, depthWrite: false, transparent: true });
  const sun = new THREE.Sprite(sunMat); sun.scale.set(70, 70, 1); scene.add(sun);
  const sunCore = new THREE.Mesh(new THREE.CircleGeometry(11, 40), new THREE.MeshBasicMaterial({ color: 0xffe7a8, fog: false }));
  scene.add(sunCore);
  const clouds = [];
  for (let i = 0; i < 9; i++) {
    const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: cloudTex, fog: false, transparent: true, depthWrite: false, opacity: 0.8 }));
    s.scale.set(60 + Math.random() * 50, 22 + Math.random() * 10, 1);
    s.userData = { x: (Math.random() * 2 - 1) * 120, y: 26 + Math.random() * 30, dz: Math.random() * 300 };
    scene.add(s); clouds.push(s);
  }

  // ================================================================== materials (cel-shaded)
  const grad = new THREE.DataTexture(new Uint8Array([70, 150, 220, 255]), 4, 1, THREE.LuminanceFormat);
  grad.minFilter = grad.magFilter = THREE.NearestFilter; grad.generateMipmaps = false; grad.needsUpdate = true;
  const toon = (c, extra) => new THREE.MeshToonMaterial(Object.assign({ color: c, gradientMap: grad }, extra || {}));
  const OUTLINE = new THREE.MeshBasicMaterial({ color: 0x1c1024, side: THREE.BackSide });
  const M = {
    skin: toon(0xf3cba2), orange: toon(0xec7634), pants: toon(0x34406a), cap: toon(0x2c966e), capD: toon(0x1f6f51),
    pack: toon(0xaab2bf), yellow: toon(0xffd646), dark: toon(0x2a2632), hair: toon(0x5c3a24), shoe: toon(0x26262e),
    wood: toon(0xc48e52), woodD: toon(0x8c5f34), red: toon(0xd8483e), blue: toon(0x3c6ec8), gold: toon(0xf0c446),
    steel: toon(0xb2b7c2), steelD: toon(0x5a5e6a), pink: toon(0xe0447a), green: toon(0x50aa5a), terra: toon(0xc8644a),
    white: toon(0xf2f2f4), glass: toon(0xc6e8f4, { emissive: 0x2a6070 }), purple: toon(0x6b4bc4), cyan: toon(0x56e0ff, { emissive: 0x1c6a80 }),
    parapet: toon(0x8a4a44), roofs: [], facades: [], balloon: toon(0xe8434f, { emissive: 0x401010 }), brick: toon(0xb5543c),
    glowSp: (c) => new THREE.SpriteMaterial({ map: glowTex, color: c, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending, fog: false }),
    shadowBlob: new THREE.MeshBasicMaterial({ color: 0x1a0a20, transparent: true, opacity: 0.3, depthWrite: false }),
    laser: new THREE.MeshBasicMaterial({ color: 0xff3b5c, transparent: true, opacity: 0.8, depthWrite: false, blending: THREE.AdditiveBlending }),
    bolt: new THREE.MeshBasicMaterial({ color: 0xffe0e6 }),
    speedLine: new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0, depthWrite: false, fog: false }),
  };
  function facade(base, lit) {
    const colorC = document.createElement("canvas"), emC = document.createElement("canvas");
    colorC.width = emC.width = 128; colorC.height = emC.height = 256;
    const g = colorC.getContext("2d"), e = emC.getContext("2d");
    g.fillStyle = base; g.fillRect(0, 0, 128, 256); e.fillStyle = "#000"; e.fillRect(0, 0, 128, 256);
    for (let y = 10; y < 256; y += 30) for (let x = 10; x < 128; x += 28) {
      if (Math.random() < lit) { const c = Math.random() < 0.8 ? "#ffcf86" : "#9ae6ff"; g.fillStyle = c; e.fillStyle = c; e.fillRect(x, y, 14, 18); }
      else g.fillStyle = "rgba(30,14,40,0.8)";
      g.fillRect(x, y, 14, 18);
    }
    const t1 = new THREE.CanvasTexture(colorC), t2 = new THREE.CanvasTexture(emC);
    for (const t of [t1, t2]) { t.wrapS = t.wrapT = THREE.RepeatWrapping; t.repeat.set(2, 6); }
    return new THREE.MeshToonMaterial({ map: t1, emissiveMap: t2, emissive: 0xffffff, emissiveIntensity: 0.85, gradientMap: grad });
  }
  function roofMat(base, line) {
    const t = canvasTex(128, 128, (g) => {
      g.fillStyle = base; g.fillRect(0, 0, 128, 128);
      g.strokeStyle = line; g.lineWidth = 3;
      for (let i = 0; i <= 128; i += 32) { g.beginPath(); g.moveTo(0, i); g.lineTo(128, i); g.stroke(); g.beginPath(); g.moveTo(i, 0); g.lineTo(i, 128); g.stroke(); }
    });
    t.wrapS = t.wrapT = THREE.RepeatWrapping; t.repeat.set(3, 8);
    return new THREE.MeshToonMaterial({ map: t, gradientMap: grad });
  }
  M.roofs.push(roofMat("#c07a5e", "rgba(90,40,40,.5)"), roofMat("#7a8f86", "rgba(40,60,55,.5)"), roofMat("#8a7fa8", "rgba(50,40,80,.5)"));
  for (const [b, l] of [["#8e4a52", 0.35], ["#6d3c66", 0.45], ["#9a5a48", 0.3], ["#4f4470", 0.5]]) M.facades.push(facade(b, l));

  const BOX = new THREE.BoxGeometry(1, 1, 1);
  const CYL = new THREE.CylinderGeometry(0.5, 0.5, 1, 18);
  const SPH = new THREE.SphereGeometry(0.5, 16, 12);
  const CONE = new THREE.ConeGeometry(0.5, 1, 16);
  const DISC = new THREE.CircleGeometry(0.5, 24);
  const OCTA = new THREE.OctahedronGeometry(0.5, 0);

  function part(geo, m, sx, sy, sz, x = 0, y = 0, z = 0, parent) {
    const o = new THREE.Mesh(geo, m);
    o.scale.set(sx, sy, sz); o.position.set(x, y, z);
    o.castShadow = true;
    if (parent) parent.add(o);
    return o;
  }
  function outline(root, k = 1.07) {
    const meshes = [];
    root.traverse((o) => { if (o.isMesh && !o.userData.outline && o.material !== M.shadowBlob) meshes.push(o); });
    for (const m of meshes) {
      const ol = new THREE.Mesh(m.geometry, OUTLINE);
      ol.userData.outline = true; ol.scale.setScalar(k); ol.castShadow = false;
      m.add(ol);
    }
    return root;
  }

  // ================================================================== city backdrop
  let backdropGroup;
  (function backdrop() {
    const far = new THREE.MeshLambertMaterial({ color: 0x8a4a7e });
    const far2 = new THREE.MeshLambertMaterial({ color: 0x6a3a72 });
    const count = 160;
    const inst = new THREE.InstancedMesh(BOX, far, count), inst2 = new THREE.InstancedMesh(BOX, far2, count);
    const m4 = new THREE.Matrix4();
    for (let i = 0; i < count; i++) {
      const side = i % 2 ? 1 : -1;
      const h = 8 + Math.random() * 28;
      m4.compose(new THREE.Vector3(side * (34 + Math.random() * 30), -22 + h / 2 - 6, -i * 9 + 40), new THREE.Quaternion(),
                 new THREE.Vector3(6 + Math.random() * 8, h, 6 + Math.random() * 8));
      inst.setMatrixAt(i, m4);
      const h2 = 14 + Math.random() * 45;
      m4.compose(new THREE.Vector3(side * (62 + Math.random() * 45), -20 + h2 / 2, -i * 9 + 40), new THREE.Quaternion(),
                 new THREE.Vector3(10 + Math.random() * 12, h2, 10 + Math.random() * 12));
      inst2.setMatrixAt(i, m4);
    }
    inst.frustumCulled = inst2.frustumCulled = false;
    backdropGroup = new THREE.Group(); backdropGroup.add(inst); backdropGroup.add(inst2);
    scene.add(backdropGroup);
  })();

  // speed lines
  const speedLines = [];
  for (let i = 0; i < 36; i++) {
    const m = new THREE.Mesh(BOX, M.speedLine);
    const a = Math.random() * Math.PI * 2, r = 3 + Math.random() * 5;
    m.userData = { a, r, z: Math.random() * 30 };
    m.scale.set(0.04, 0.04, 2 + Math.random() * 3);
    scene.add(m); speedLines.push(m);
  }

  // particles
  const PCOL = [0xffd646, 0xff5d7a, 0x7af0ff, 0x2ed38f, 0xc38bff, 0xd9c7b5, 0xffffff];
  const PMAT = PCOL.map((c) => new THREE.MeshBasicMaterial({ color: c, transparent: true }));
  const particles = [];
  for (let i = 0; i < 160; i++) { const p = new THREE.Mesh(BOX, PMAT[0]); p.visible = false; scene.add(p); particles.push({ m: p, life: 0 }); }
  let pIdx = 0;
  function burst(pos, n, colors, speed = 5, size = 0.14, up = 4, life = 0.8, grav = 14) {
    for (let i = 0; i < n; i++) {
      const p = particles[pIdx = (pIdx + 1) % particles.length];
      p.m.material = PMAT[colors[i % colors.length]];
      p.m.position.copy(pos); p.m.visible = true; p.m.scale.setScalar(size * (0.6 + Math.random() * 0.8));
      p.v = new THREE.Vector3((Math.random() - 0.5) * speed, Math.random() * up + 1, (Math.random() - 0.5) * speed);
      p.life = p.max = life * (0.6 + Math.random() * 0.6); p.g = grav; p.spin = (Math.random() - 0.5) * 12;
    }
  }
  function updateParticles(dt) {
    for (const p of particles) {
      if (p.life <= 0) continue;
      p.life -= dt;
      if (p.life <= 0) { p.m.visible = false; continue; }
      p.v.y -= p.g * dt; p.m.position.addScaledVector(p.v, dt);
      p.m.rotation.x += p.spin * dt; p.m.rotation.y += p.spin * dt;
      p.m.material.opacity = Math.min(1, p.life / p.max * 2);
    }
  }

  // ================================================================== hero
  const H = { body: toon(0xec7634), pants: toon(0x34406a), cap: toon(0x2c966e), capD: toon(0x1f6f51), skin: toon(0xf3cba2) };
  function applySkin(sk) {
    H.body.color.setHex(sk.body); H.pants.color.setHex(sk.pants); H.cap.color.setHex(sk.cap);
    H.capD.color.setHex(sk.capD); H.skin.color.setHex(sk.skin);
  }
  function makeHero() {
    const root = new THREE.Group();
    const body = new THREE.Group(); root.add(body);
    const legs = [], arms = [];
    for (const s of [-1, 1]) {
      const hip = new THREE.Group(); hip.position.set(0.17 * s, 0.58, 0); body.add(hip);
      part(BOX, H.pants, 0.24, 0.5, 0.24, 0, -0.25, 0, hip);
      part(BOX, M.shoe, 0.28, 0.14, 0.38, 0, -0.52, 0.06, hip);
      legs.push(hip);
      const sh = new THREE.Group(); sh.position.set(0.43 * s, 1.18, 0); body.add(sh);
      part(BOX, H.body, 0.2, 0.52, 0.2, 0, -0.25, 0, sh);
      part(BOX, H.skin, 0.21, 0.16, 0.21, 0, -0.57, 0, sh);
      arms.push(sh);
    }
    part(BOX, H.body, 0.64, 0.64, 0.42, 0, 0.9, 0, body);
    part(BOX, M.yellow, 0.66, 0.08, 0.44, 0, 0.64, 0, body);
    part(BOX, M.yellow, 0.16, 0.16, 0.04, 0.12, 1.02, 0.22, body);
    part(BOX, H.skin, 0.68, 0.64, 0.64, 0, 1.49, 0, body);
    part(BOX, M.hair, 0.68, 0.46, 0.08, 0, 1.52, -0.33, body);
    part(BOX, H.cap, 0.73, 0.16, 0.71, 0, 1.83, 0, body);
    part(BOX, H.capD, 0.6, 0.06, 0.3, 0, 1.77, 0.44, body);
    part(BOX, M.dark, 0.1, 0.15, 0.04, -0.14, 1.53, 0.33, body);
    part(BOX, M.dark, 0.1, 0.15, 0.04, 0.14, 1.53, 0.33, body);
    part(BOX, M.dark, 0.16, 0.04, 0.04, 0, 1.33, 0.33, body);
    part(BOX, M.pack, 0.5, 0.56, 0.24, 0, 0.92, -0.33, body);
    part(BOX, M.yellow, 0.12, 0.4, 0.04, 0, 0.94, -0.46, body);
    outline(root);
    const flame = new THREE.Mesh(CONE, new THREE.MeshBasicMaterial({ color: 0xffa040 }));
    flame.scale.set(0.22, 0.45, 0.22); flame.position.set(0, 0.45, -0.33); flame.rotation.x = Math.PI; flame.visible = false;
    body.add(flame);
    const flameGlow = new THREE.Sprite(M.glowSp(0xff9a40)); flameGlow.scale.set(1.4, 1.4, 1); flameGlow.position.set(0, 0.35, -0.33); flame.add(flameGlow);
    const dashGlow = new THREE.Sprite(M.glowSp(0x7af0ff)); dashGlow.scale.set(3.2, 3.2, 1); dashGlow.position.set(0, 1, 0.2);
    dashGlow.material.opacity = 0; body.add(dashGlow);
    const towerBase = new THREE.Group(); towerBase.position.set(0, 1.22, -0.36); body.add(towerBase);
    const blob = new THREE.Mesh(DISC, M.shadowBlob); blob.rotation.x = -Math.PI / 2; blob.scale.set(1.3, 1, 1);
    scene.add(blob);
    root.rotation.y = Math.PI;
    return { root, body, legs, arms, flame, towerBase, blob, dashGlow };
  }

  // ================================================================== items
  function makeItem(type) {
    const g = new THREE.Group();
    switch (type.id) {
      case "crate":
        part(BOX, M.wood, 0.8, 0.6, 0.62, 0, 0.3, 0, g); part(BOX, M.woodD, 0.82, 0.08, 0.64, 0, 0.3, 0, g); break;
      case "chest":
        part(BOX, M.woodD, 0.82, 0.42, 0.54, 0, 0.21, 0, g);
        { const lid = part(CYL, M.wood, 0.42, 0.82, 0.54, 0, 0.42, 0, g); lid.rotation.z = Math.PI / 2; }
        part(BOX, M.gold, 0.84, 0.07, 0.56, 0, 0.42, 0, g); part(BOX, M.gold, 0.14, 0.18, 0.06, 0, 0.3, 0.28, g); break;
      case "shield":
        part(CYL, M.blue, 0.86, 0.12, 0.86, 0, 0.06, 0, g); part(CYL, M.gold, 0.56, 0.14, 0.56, 0, 0.08, 0, g);
        part(CYL, M.steel, 0.2, 0.2, 0.2, 0, 0.12, 0, g); break;
      case "lamp":
        part(CYL, M.steelD, 0.4, 0.06, 0.4, 0, 0.03, 0, g); part(CYL, M.steelD, 0.08, 0.45, 0.08, 0, 0.27, 0, g);
        { const sh = new THREE.Mesh(new THREE.CylinderGeometry(0.2, 0.36, 0.32, 16), toon(0xffd646, { emissive: 0x806010 })); sh.position.y = 0.6; sh.castShadow = true; g.add(sh); }
        break;
      case "potion":
        part(SPH, toon(0xe0447a, { emissive: 0x501030 }), 0.5, 0.5, 0.5, 0, 0.25, 0, g); part(CYL, M.glass, 0.16, 0.22, 0.16, 0, 0.55, 0, g);
        part(CYL, M.woodD, 0.18, 0.06, 0.18, 0, 0.67, 0, g); break;
      case "cactus":
        { const pot = new THREE.Mesh(new THREE.CylinderGeometry(0.26, 0.2, 0.3, 16), M.terra); pot.position.y = 0.15; pot.castShadow = true; g.add(pot); }
        part(CYL, M.green, 0.22, 0.5, 0.22, 0, 0.55, 0, g); part(CYL, M.green, 0.12, 0.24, 0.12, -0.18, 0.62, 0, g);
        part(CYL, M.green, 0.12, 0.2, 0.12, 0.18, 0.7, 0, g); break;
      case "pan":
        part(CYL, M.dark, 0.7, 0.12, 0.7, 0, 0.06, 0, g); part(BOX, M.dark, 0.5, 0.06, 0.1, 0.55, 0.1, 0, g); break;
      case "duck":
        part(SPH, M.yellow, 0.6, 0.42, 0.5, 0, 0.21, 0, g); part(SPH, M.yellow, 0.34, 0.34, 0.34, 0.18, 0.5, 0, g);
        { const b = part(CONE, M.orange, 0.12, 0.18, 0.12, 0.38, 0.48, 0, g); b.rotation.z = -Math.PI / 2; }
        part(BOX, M.dark, 0.04, 0.05, 0.05, 0.3, 0.56, 0.12, g); break;
      case "rocket":
        part(CYL, M.white, 0.3, 0.55, 0.3, 0, 0.35, 0, g); part(CONE, M.red, 0.3, 0.3, 0.3, 0, 0.77, 0, g);
        part(CYL, M.glass, 0.12, 0.12, 0.12, 0, 0.45, 0.14, g).rotation.x = Math.PI / 2;
        for (const s of [-1, 1]) part(BOX, M.red, 0.06, 0.24, 0.2, 0.17 * s, 0.14, 0, g);
        break;
      case "tv":
        part(BOX, M.steelD, 0.8, 0.52, 0.4, 0, 0.29, 0, g); part(BOX, M.cyan, 0.62, 0.38, 0.02, 0, 0.3, 0.21, g);
        part(BOX, M.dark, 0.04, 0.2, 0.04, -0.1, 0.62, 0, g).rotation.z = 0.4; part(BOX, M.dark, 0.04, 0.2, 0.04, 0.1, 0.62, 0, g).rotation.z = -0.4;
        break;
      case "gem":
        part(OCTA, M.cyan, 0.5, 0.55, 0.5, 0, 0.28, 0, g); break;
      case "balloon":
        part(SPH, M.balloon, 0.55, 0.62, 0.55, 0, 0.44, 0, g); part(BOX, M.white, 0.025, 0.2, 0.025, 0, 0.08, 0, g);
        part(CONE, M.balloon, 0.12, 0.08, 0.12, 0, 0.13, 0, g); break;
      case "brick":
        part(BOX, M.brick, 0.8, 0.3, 0.42, 0, 0.15, 0, g);
        for (const x of [-0.2, 0.2]) part(CYL, M.dark, 0.14, 0.04, 0.14, x, 0.3, 0, g);
        break;
      case "magnet":
        part(BOX, M.red, 0.16, 0.34, 0.22, -0.2, 0.25, 0, g); part(BOX, M.red, 0.16, 0.34, 0.22, 0.2, 0.25, 0, g);
        part(BOX, M.red, 0.56, 0.12, 0.22, 0, 0.39, 0, g);
        for (const x of [-0.2, 0.2]) part(BOX, M.steel, 0.16, 0.1, 0.22, x, 0.05, 0, g);
        break;
    }
    return outline(g, 1.09);
  }

  // ================================================================== state
  let state = "menu";
  const hero = makeHero();
  scene.add(hero.root);
  const S = {};
  const segs = [];
  const things = [];
  const showBest = () => {
    const d = P.get();
    $("bestLine").textContent = d.best ? "Рекорд: ★ " + d.best + " · " + d.bestDist + " м" : "";
  };
  showBest();

  function clearWorld() {
    for (const s of segs) scene.remove(s.group);
    segs.length = 0;
    for (const t of things) { if (t.obj) scene.remove(t.obj); if (t.laser) scene.remove(t.laser); }
    things.length = 0;
    while (hero.towerBase.children.length) hero.towerBase.remove(hero.towerBase.children[0]);
  }
  function resetRun() {
    clearWorld();
    Object.assign(S, {
      x: 0, y: 0, z: 0, vx: 0, vy: 0, ax: 0, speed: 11, onGround: true, coyote: 0, jumpBuf: 0, jumpsLeft: 0,
      tower: [], theta: 0, omega: 0, pitch: 0, pitchV: 0, bank: 0, pool: 0, phase: 0, genZ: 8, nextCpGen: CP_EVERY,
      stumble: 0, droneTimer: 6, time: 0, camX: 0, camY: 4, camZ: 8, lastSeg: null, wind: 0, windT: 0,
      dash: 0, dashCd: 0, combo: 0, comboT: 0, shake: 0, fovKick: 0, rocketT: 0, segN: 0,
      saves: P.level("insurance"), tiltMax: TILT_MAX + 0.035 * P.level("frame"),
      dashCdMax: 2.6 - 0.3 * P.level("dash"), dashLen: 0.5 + 0.06 * P.level("dash"),
      questDone: [], tut: { stage: 0, steerT: 0, gapTip: false, gateTip: false, t: 0 },
    });
    addSegment(60, 0, 8);
    while (S.genZ > -180) genNext();
    updateHud(true);
  }

  // ================================================================== level
  function addSegment(len, y, z0) {
    const zEnd = z0 - len, zc = (z0 + zEnd) / 2;
    const group = new THREE.Group();
    const f = M.facades[S.segN % M.facades.length];
    const b = new THREE.Mesh(BOX, [f, f, M.roofs[S.segN % M.roofs.length], f, f, f]);
    b.scale.set(ROOF_HALF * 2 + 1.4, 40, len); b.position.set(0, y - 20, zc);
    b.receiveShadow = true; group.add(b);
    for (const s of [-1, 1]) { const p = part(BOX, M.parapet, 0.3, 0.38, len, s * (ROOF_HALF + 0.55), y + 0.19, zc, group); p.receiveShadow = true; }
    // flanking lower buildings with neon ads
    for (const s of [-1, 1]) {
      if (Math.random() < 0.25) continue;
      const h = 30 + Math.random() * 6, w = 6 + Math.random() * 3;
      const nf = M.facades[(S.segN + 1 + (s > 0 ? 1 : 0)) % M.facades.length];
      const nb = new THREE.Mesh(BOX, [nf, nf, M.roofs[(S.segN + 1) % M.roofs.length], nf, nf, nf]);
      const by = y - 3 - Math.random() * 6;
      nb.scale.set(w, h, Math.min(len, 18 + Math.random() * 10)); nb.position.set(s * (ROOF_HALF + 3.2 + w / 2), by - h / 2, zc);
      group.add(nb);
      if (Math.random() < 0.7) {
        const [txt, col] = AD_TEXTS[Math.floor(Math.random() * AD_TEXTS.length)];
        const sign = new THREE.Mesh(new THREE.PlaneGeometry(5.2, 1.6), new THREE.MeshBasicMaterial({ map: adTexture(txt, col), transparent: true, fog: true }));
        sign.position.set(s * (ROOF_HALF + 3.6), by + 2.4, zc + (Math.random() - 0.5) * 6);
        sign.rotation.y = -s * 0.9;
        group.add(sign);
        for (const px of [-2, 2]) part(BOX, M.steelD, 0.1, 2.2, 0.1, sign.position.x + px * Math.cos(sign.rotation.y) * 0.8, by + 1.1, sign.position.z - px * Math.sin(sign.rotation.y) * 0.8, group);
      }
    }
    // string lights across the roof
    if (S.segN % 2 === 1 && len > 26) {
      const zz = zc + (Math.random() - 0.5) * (len - 16);
      for (let i = 0; i <= 10; i++) {
        const u = i / 10, x = -ROOF_HALF - 0.5 + u * (ROOF_HALF * 2 + 1), yy = y + 4.6 - Math.sin(u * Math.PI) * 0.9;
        const bulb = new THREE.Sprite(M.glowSp([0xffd646, 0xff5d7a, 0x7af0ff, 0x2ed38f][i % 4]));
        bulb.scale.set(0.9, 0.9, 1); bulb.position.set(x, yy, zz); group.add(bulb);
      }
      for (const s of [-1, 1]) part(BOX, M.steelD, 0.12, 4.6, 0.12, s * (ROOF_HALF + 0.55), y + 2.3, zz, group);
    }
    // decorations on wide roofs
    if (Math.random() < 0.5) {
      const tank = new THREE.Group();
      part(CYL, M.woodD, 1.6, 1.8, 1.6, 0, 2.6, 0, tank); part(CONE, M.dark, 1.8, 0.8, 1.8, 0, 3.9, 0, tank);
      for (const [lx, lz] of [[-0.6, -0.6], [0.6, -0.6], [-0.6, 0.6], [0.6, 0.6]]) part(BOX, M.steelD, 0.12, 1.8, 0.12, lx, 0.9, lz, tank);
      tank.position.set((Math.random() < 0.5 ? -1 : 1) * (ROOF_HALF + 2.3), y, zc + (Math.random() - 0.5) * len * 0.6);
      group.add(tank);
    }
    scene.add(group);
    const seg = { z0, z1: zEnd, y, group };
    segs.push(seg);
    S.genZ = zEnd; S.lastSeg = seg; S.segN++;
    return seg;
  }
  const adCache = {};
  function adTexture(txt, col) {
    if (adCache[txt]) return adCache[txt];
    const t = canvasTex(512, 160, (g) => {
      g.fillStyle = "rgba(20,8,30,.82)"; g.fillRect(0, 0, 512, 160);
      g.strokeStyle = col; g.lineWidth = 10; g.shadowColor = col; g.shadowBlur = 24; g.strokeRect(10, 10, 492, 140);
      g.fillStyle = col; g.font = "64px 'Russo One', 'Russo One Local', 'Arial Black', sans-serif";
      g.textAlign = "center"; g.textBaseline = "middle"; g.fillText(txt, 256, 84);
    });
    return (adCache[txt] = t);
  }

  function genNext() {
    const dist = -S.genZ;
    const hard = Math.min(1, dist / 1600);
    const gap = 2.6 + Math.random() * (2.0 + hard * 2.6);
    const len = 22 + Math.random() * 28;
    const prevY = S.lastSeg ? S.lastSeg.y : 0;
    let y = prevY + (Math.random() * 1.8 - 0.9);
    y = Math.max(-2, Math.min(2, Math.min(y, prevY + 0.7)));
    const seg = addSegment(len, y, S.genZ - gap);
    let gd = S.nextCpGen;
    if (gd < -seg.z0 + 6) gd = -seg.z0 + 8;
    if (gd <= -seg.z1 - 6) { addGate(seg, -gd); S.nextCpGen = gd + CP_EVERY; }
    populate(seg, hard);
  }

  function populate(seg, hard) {
    let z = seg.z0 - 6;
    let lineMode = 0;
    while (z > seg.z1 + 5) {
      if (things.some((t) => t.gate && Math.abs(t.z - z) < 7)) { z -= 4; continue; }
      const r = Math.random();
      const x = (Math.random() * 2 - 1) * (ROOF_HALF - 0.8);
      if (r < 0.14 && !lineMode) {
        // a line of pickups weaving across the roof: combo bait
        const x0 = (Math.random() * 2 - 1) * 2.5, dir = Math.random() < 0.5 ? -1 : 1;
        for (let i = 0; i < 4 && z > seg.z1 + 4; i++) { addPickup(Math.max(-3.4, Math.min(3.4, x0 + dir * i * 0.9)), seg.y + 1.1, z); z -= 2.6; }
        lineMode = 1;
        continue;
      }
      lineMode = 0;
      if (r < 0.5) addPickup(x, seg.y + 1.1, z);
      else if (r < 0.78 + hard * 0.12) {
        addObstacle(x, seg.y, z);
        if (hard > 0.35 && Math.random() < 0.35) addObstacle(x > 0 ? x - 2.4 : x + 2.4, seg.y, z);
      }
      z -= 4.5 + Math.random() * (6.5 - hard * 2.5);
    }
  }

  function pickRandomType() {
    const r = Math.random();
    if (r < 0.04) return TYPE.gem;
    if (r < 0.12) return TYPE.balloon;
    if (r < 0.19) return TYPE.brick;
    if (r < 0.25) return TYPE.magnet;
    return ITEM_TYPES[Math.floor(Math.random() * 10)];
  }
  function addPickup(x, y, z) {
    const type = pickRandomType();
    const g = new THREE.Group();
    const it = makeItem(type); it.position.y = -type.h / 2; g.add(it);
    const glow = new THREE.Sprite(M.glowSp(type.id === "gem" ? 0x7af0ff : 0xffd27a)); glow.scale.set(2.2, 2.2, 1); g.add(glow);
    g.position.set(x, y, z);
    scene.add(g);
    things.push({ kind: "pickup", type, obj: g, x, y, z, ph: Math.random() * 6 });
  }
  function addObstacle(x, y, z) {
    const g = new THREE.Group();
    if (Math.random() < 0.6) { part(BOX, M.steel, 1.4, 0.9, 1.0, 0, 0.45, 0, g); part(CYL, M.steelD, 0.7, 0.05, 0.7, 0, 0.92, 0, g); part(BOX, M.dark, 1.2, 0.5, 0.04, 0, 0.45, 0.51, g); }
    else { part(BOX, M.terra, 1.0, 1.1, 1.0, 0, 0.55, 0, g); part(BOX, M.parapet, 1.2, 0.15, 1.2, 0, 1.1, 0, g); }
    g.traverse((o) => { if (o.isMesh) o.receiveShadow = true; });
    g.position.set(x, y, z);
    scene.add(g);
    things.push({ kind: "obstacle", obj: g, x, y, z, hw: 0.75, h: 1.05 });
  }

  function signTexture(text, bg) {
    return canvasTex(512, 128, (g) => {
      g.fillStyle = bg; g.fillRect(0, 0, 512, 128);
      g.strokeStyle = "rgba(255,255,255,.85)"; g.lineWidth = 8; g.strokeRect(4, 4, 504, 120);
      g.fillStyle = "#fff"; g.font = "46px 'Russo One', 'Russo One Local', 'Arial Black', sans-serif";
      g.textAlign = "center"; g.textBaseline = "middle"; g.fillText(text, 256, 66);
    });
  }
  let SIGN_BANK = signTexture("◀ СДАТЬ ДОБЫЧУ", "#1f9e6c");
  let SIGN_RISK = signTexture("РИСК ДАЛЬШЕ ▶", "#7a3cc4");
  document.fonts?.ready?.then(() => {
    SIGN_BANK = signTexture("◀ СДАТЬ ДОБЫЧУ", "#1f9e6c"); SIGN_RISK = signTexture("РИСК ДАЛЬШЕ ▶", "#7a3cc4");
    for (const k in adCache) delete adCache[k];
  });

  function addGate(seg, z) {
    const g = new THREE.Group();
    const y = seg.y;
    const neonG = new THREE.MeshBasicMaterial({ color: 0x2ed38f }), neonP = new THREE.MeshBasicMaterial({ color: 0xb07aff }), neonW = new THREE.MeshBasicMaterial({ color: 0xffe9b0 });
    part(BOX, neonG, 0.3, 3.8, 0.3, -ROOF_HALF - 0.3, y + 1.9, 0, g);
    part(BOX, neonW, 0.3, 3.8, 0.3, 0, y + 1.9, 0, g);
    part(BOX, neonP, 0.3, 3.8, 0.3, ROOF_HALF + 0.3, y + 1.9, 0, g);
    part(BOX, neonG, ROOF_HALF + 0.5, 0.3, 0.3, -ROOF_HALF / 2 - 0.2, y + 3.8, 0, g);
    part(BOX, neonP, ROOF_HALF + 0.5, 0.3, 0.3, ROOF_HALF / 2 + 0.2, y + 3.8, 0, g);
    const s1 = new THREE.Mesh(new THREE.PlaneGeometry(3.6, 0.9), new THREE.MeshBasicMaterial({ map: SIGN_BANK })); s1.position.set(-2.1, y + 3.1, 0.2); g.add(s1);
    const s2 = new THREE.Mesh(new THREE.PlaneGeometry(3.6, 0.9), new THREE.MeshBasicMaterial({ map: SIGN_RISK })); s2.position.set(2.1, y + 3.1, 0.2); g.add(s2);
    for (const [x, c] of [[-2.05, 0x2ed38f], [2.05, 0x9a5cf0]]) {
      const st = new THREE.Mesh(new THREE.PlaneGeometry(3.8, 2.4), new THREE.MeshBasicMaterial({ color: c, transparent: true, opacity: 0.5, depthWrite: false }));
      st.rotation.x = -Math.PI / 2; st.position.set(x, y + 0.03, 0); g.add(st);
      const gl = new THREE.Sprite(M.glowSp(c)); gl.scale.set(6, 5, 1); gl.position.set(x, y + 2, -0.2); g.add(gl);
    }
    g.position.z = z;
    scene.add(g);
    things.push({ kind: "gate", gate: true, obj: g, z, used: false });
  }

  function addDrone() {
    const seg = segAt(S.z - 46) || S.lastSeg;
    const g = new THREE.Group();
    part(SPH, M.steelD, 1.0, 0.45, 0.8, 0, 0, 0, g);
    part(SPH, new THREE.MeshBasicMaterial({ color: 0xff3b5c }), 0.28, 0.28, 0.28, 0, -0.05, 0.38, g);
    const rotors = [];
    for (const s of [-1, 1]) {
      part(BOX, M.dark, 0.06, 0.25, 0.06, s * 0.55, 0.25, 0, g);
      rotors.push(part(CYL, new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.35, depthWrite: false }), 0.9, 0.02, 0.9, s * 0.55, 0.38, 0, g));
    }
    outline(g, 1.08);
    const eye = new THREE.Sprite(M.glowSp(0xff3b5c)); eye.scale.set(1.4, 1.4, 1); eye.position.set(0, -0.05, 0.45); g.add(eye);
    const x = (Math.random() * 2 - 1) * 3, y = (seg ? seg.y : 0) + 5.2, z = S.z - 46;
    g.position.set(x, y, z);
    scene.add(g);
    const laser = new THREE.Mesh(CYL, M.laser); laser.visible = false; scene.add(laser);
    things.push({ kind: "drone", obj: g, laser, x, y, z, st: "idle", t: 0, rotors, eye });
  }

  function segAt(z) { for (const s of segs) if (z <= s.z0 && z >= s.z1) return s; return null; }

  // ================================================================== tower
  function towerHeight() { return S.tower.reduce((a, t) => a + t.type.h, 0); }
  function addToTower(type) {
    const parent = S.tower.length ? S.tower[S.tower.length - 1].link : hero.towerBase;
    const link = new THREE.Group();
    link.position.y = S.tower.length ? S.tower[S.tower.length - 1].type.h : 0;
    const it = makeItem(type);
    it.rotation.y = (Math.random() - 0.5) * 0.6; it.position.x = (Math.random() - 0.5) * 0.08;
    link.add(it); parent.add(link);
    link.scale.setScalar(1.35); link.userData.pop = 0.2;
    S.tower.push({ type, link });
    S.omega += (Math.random() - 0.5) * 0.4;
  }
  function dropTop(dir) {
    if (!S.tower.length) return;
    if (S.saves > 0) {
      S.saves--;
      const tp = new THREE.Vector3(); S.tower[S.tower.length - 1].link.getWorldPosition(tp);
      pop("Страховка!", "neon", tp); Audio.play("near"); burst(tp, 10, [2, 6], 4, 0.12, 3, 0.5);
      S.theta *= 0.3; S.omega *= 0.2;
      return;
    }
    const top = S.tower.pop();
    const wp = new THREE.Vector3(); top.link.getWorldPosition(wp);
    const wq = new THREE.Quaternion(); top.link.getWorldQuaternion(wq);
    top.link.parent.remove(top.link);
    const obj = top.link; obj.position.copy(wp); obj.quaternion.copy(wq); obj.scale.setScalar(1);
    scene.add(obj);
    const side = dir || Math.sign(S.theta) || (Math.random() < 0.5 ? -1 : 1);
    things.push({ kind: "falling", obj, vx: side * 4 + S.vx * 0.3, vy: 4, vz: -S.speed * 0.6, spin: (Math.random() - 0.5) * 8, t: 0 });
    pop("−1 " + top.type.name, "bad", wp);
    S.combo = 0; S.comboT = 0;
    Audio.play("drop"); buzz(40); flashVignette();
  }
  function bankTower(pos) {
    if (!S.tower.length && !S.pool) { pop("Башня пуста", "bad"); return; }
    const sum = S.tower.reduce((a, t) => a + t.type.value, 0);
    const gain = Math.round(sum * multiplier()) + S.pool;
    quest("bigbank", S.tower.length); quest("banktotal", gain);
    if (state === "play" && !P.tutorialDone()) { P.finishTutorial(); setTimeout(() => tip("Отлично! Звёзды из банка тратятся в Гараже на улучшения и образы", 4.5), 900); }
    S.bank += gain; S.pool = 0;
    while (S.tower.length) { const t = S.tower.pop(); const wp = new THREE.Vector3(); t.link.getWorldPosition(wp); burst(wp, 4, [0, 3, 6], 6, 0.16, 6, 1); t.link.parent.remove(t.link); }
    S.theta *= 0.2; S.omega = 0;
    pop("+" + gain + " в банк!", "bank");
    burst(pos, 60, [0, 1, 2, 3, 4], 14, 0.2, 10, 1.6, 12);
    flash(0.55); S.shake = 0.5;
    Audio.play("bank"); buzz([30, 40, 30]);
  }
  function multiplier() { return 1 + Math.max(0, S.tower.length - 1) * 0.25; }
  function hasRocket() { return S.tower.some((t) => t.type.id === "rocket"); }
  function countType(id) { let c = 0; for (const t of S.tower) if (t.type.id === id) c++; return c; }
  function quest(id, v) {
    if (state !== "play") return;
    const done = P.questEvent(id, v);
    for (const txt of done) { S.questDone.push(txt); pop("Задание выполнено!", "neon"); Audio.play("bank"); }
  }

  // ================================================================== input
  const input = { steer: 0, keys: new Set(), touchId: null, tx: 0 };
  const stick = $("stick"), knob = $("knob");
  window.addEventListener("keydown", (e) => {
    input.keys.add(e.code);
    if (["Space", "ArrowUp", "KeyW"].includes(e.code)) { requestJump(); e.preventDefault(); }
    if (["ShiftLeft", "ShiftRight", "KeyS", "ArrowDown"].includes(e.code)) requestDash();
    if (e.code === "Escape" || e.code === "KeyP") togglePause();
  });
  window.addEventListener("keyup", (e) => input.keys.delete(e.code));
  function requestJump() { if (state === "play") S.jumpBuf = 0.15; }
  function requestDash() {
    if (state !== "play" || S.dashCd > 0) return;
    S.dash = S.dashLen; S.dashCd = S.dashCdMax; S.fovKick = 10; S.pitchV -= 2.5; S.omega += (Math.random() - 0.5) * 1.2;
    Audio.play("dash"); buzz(20);
  }
  canvas.addEventListener("pointerdown", (e) => {
    if (state !== "play") return;
    if (e.clientX < window.innerWidth * 0.55) {
      if (input.touchId === null) {
        input.touchId = e.pointerId; input.tx = e.clientX;
        stick.classList.remove("idle"); stick.style.left = e.clientX + "px"; stick.style.top = e.clientY + "px";
        try { canvas.setPointerCapture(e.pointerId); } catch (err) {}
      }
    } else requestJump();
  });
  canvas.addEventListener("pointermove", (e) => {
    if (e.pointerId !== input.touchId) return;
    const dx = Math.max(-60, Math.min(60, e.clientX - input.tx));
    input.steer = dx / 60; knob.style.transform = `translateX(${dx}px)`;
  });
  const endTouch = (e) => {
    if (e.pointerId !== input.touchId) return;
    input.touchId = null; input.steer = 0; knob.style.transform = "";
    stick.classList.add("idle"); stick.style.left = ""; stick.style.top = "";
  };
  canvas.addEventListener("pointerup", endTouch);
  canvas.addEventListener("pointercancel", endTouch);
  function holdBtn(el, fn) {
    el.addEventListener("pointerdown", (e) => { e.preventDefault(); fn(); el.classList.add("on"); });
    for (const ev of ["pointerup", "pointercancel", "pointerleave"]) el.addEventListener(ev, () => el.classList.remove("on"));
  }
  holdBtn($("jumpBtn"), requestJump);
  holdBtn($("dashBtn"), requestDash);
  const keySteer = () => (input.keys.has("ArrowLeft") || input.keys.has("KeyA") ? -1 : 0) + (input.keys.has("ArrowRight") || input.keys.has("KeyD") ? 1 : 0);

  // ================================================================== HUD
  const popsEl = $("pops");
  const projV = new THREE.Vector3();
  function pop(text, cls, worldPos) {
    if (state !== "play") return;
    const el = document.createElement("div");
    el.className = "pop " + cls; el.textContent = text;
    let x = window.innerWidth / 2, y = window.innerHeight * 0.36;
    if (worldPos) { projV.copy(worldPos).project(camera); x = (projV.x * 0.5 + 0.5) * window.innerWidth; y = (-projV.y * 0.5 + 0.5) * window.innerHeight; }
    el.style.left = x + "px"; el.style.top = y + "px";
    popsEl.appendChild(el);
    setTimeout(() => el.remove(), 1200);
  }
  function flash(a) { const f = $("flash"); f.style.transition = "none"; f.style.opacity = a; requestAnimationFrame(() => { f.style.transition = "opacity .35s"; f.style.opacity = 0; }); }
  function flashVignette() { const v = $("vignette"); v.style.opacity = 1; setTimeout(() => (v.style.opacity = 0), 180); }
  const hudCache = {};
  function setText(id, v) { if (hudCache[id] !== v) { hudCache[id] = v; $(id).textContent = v; } }
  const fmtMult = (m) => "×" + (Math.round(m * 100) / 100);
  function updateHud(force) {
    if (force) for (const k in hudCache) delete hudCache[k];
    setText("dist", Math.max(0, Math.round(-S.z)) + " м");
    setText("spd", Math.round(S.speed * 3.6) + " км/ч");
    setText("bank", "★ " + S.bank);
    setText("tcount", String(S.tower.length));
    setText("tmult", fmtMult(multiplier()));
    setText("tval", "на кону " + (Math.round(S.tower.reduce((a, t) => a + t.type.value, 0) * multiplier()) + S.pool));
    let gate = Infinity;
    for (const t of things) if (t.gate && !t.used && t.z < S.z) gate = Math.min(gate, S.z - t.z);
    setText("cp", gate === Infinity ? "скоро" : Math.round(gate) + " м");
    const k = Math.max(-1, Math.min(1, S.theta / S.tiltMax));
    $("needle").style.left = `calc(${50 + k * 47}% - 3.5px)`;
    const r = hasRocket(); if ($("abil").hidden === r) $("abil").hidden = !r;
    const c = $("combo");
    if (S.combo >= 2) { if (c.hidden) c.hidden = false; setText("combo", "Комбо ×" + S.combo); } else if (!c.hidden) c.hidden = true;
    $("dashBtn").style.setProperty("--cd", (360 * (1 - Math.max(0, S.dashCd) / S.dashCdMax)) + "deg");
  }

  // ================================================================== update
  function step(dt) {
    S.time += dt;
    const hard = Math.min(1, -S.z / 1600);
    const n = S.tower.length;

    const target = (11 + Math.min(10, -S.z / 120)) * (1 - Math.min(0.18, n * 0.01));
    S.speed += (target - S.speed) * Math.min(1, dt * 2);
    let fwd = S.speed;
    if (S.dash > 0) { S.dash -= dt; fwd *= 1.75; }
    S.dashCd -= dt;
    if (S.stumble > 0) { S.stumble -= dt; fwd *= 0.35; }
    S.z -= fwd * dt;
    S.comboT -= dt; if (S.comboT <= 0 && S.combo) S.combo = 0;

    const steer = Math.max(-1, Math.min(1, input.steer + keySteer()));
    const prevVx = S.vx;
    S.vx += (steer * 8 - S.vx) * Math.min(1, dt * 10);
    S.x += S.vx * dt;
    if (S.x > ROOF_HALF) { S.x = ROOF_HALF; S.vx = 0; }
    if (S.x < -ROOF_HALF) { S.x = -ROOF_HALF; S.vx = 0; }
    S.ax = (S.vx - prevVx) / Math.max(dt, 1e-4);

    const seg = segAt(S.z);
    const groundY = seg ? seg.y : -999;
    S.jumpBuf -= dt;
    if (S.onGround) S.coyote = 0.12; else S.coyote -= dt;
    if (S.jumpBuf > 0) {
      const power = 9.2 * (1 - Math.min(0.18, n * 0.012)) * (1 + 0.04 * P.level("legs"))
                  * (1 + 0.03 * countType("balloon")) * (1 - 0.03 * countType("brick"));
      if (S.onGround || S.coyote > 0) {
        S.vy = power; S.onGround = false; S.coyote = 0; S.jumpBuf = 0; S.jumpsLeft = hasRocket() ? 1 : 0;
        S.pitchV -= 1.2; Audio.play("jump");
        burst(new THREE.Vector3(S.x, S.y + 0.1, S.z), 8, [5], 3, 0.12, 1.5, 0.4, 6);
      } else if (S.jumpsLeft > 0) {
        S.vy = power * 0.95; S.jumpsLeft--; S.jumpBuf = 0; S.rocketT = 0.45;
        Audio.play("dash"); pop("Ракета!", "neon", new THREE.Vector3(S.x, S.y + 2.5, S.z));
      }
    }
    if (!S.onGround) {
      S.vy -= GRAV * dt;
      const ny = S.y + S.vy * dt;
      if (seg && S.vy <= 0 && S.y >= groundY - 0.05 && ny <= groundY) {
        S.y = groundY; S.onGround = true;
        S.omega += (Math.random() - 0.5) * 0.9 * Math.min(1.5, -S.vy / 8); S.pitchV += 1.6;
        if (S.vy < -9) { S.shake = Math.max(S.shake, 0.2); Audio.play("land"); burst(new THREE.Vector3(S.x, S.y + 0.1, S.z), 10, [5], 4, 0.14, 1.5, 0.5, 6); }
        S.vy = 0;
      } else S.y = ny;
    } else if (!seg) S.onGround = false;
    else if (groundY > S.y + 0.05) { S.y = groundY; stumble("Споткнулся!"); }
    else if (groundY < S.y - 0.05) S.onGround = false;
    else S.y = groundY;
    if (S.y < -9) { gameOver("Сорвался!", S.tower.length ? "Башня из " + S.tower.length + " вещей улетела в пропасть вместе с тобой." : "Пропасть оказалась шире прыжка."); return; }

    // tower: inverted pendulum riding on the hero's back
    if (n > 0) {
      const L = 0.9 + towerHeight() * 0.85, g = 9.8 * 0.55;
      S.windT -= dt;
      if (S.windT <= 0) { S.wind = (Math.random() - 0.5) * (0.6 + hard * 1.6); S.windT = 1 + Math.random() * 2; }
      const stab = (1 - 0.08 * P.level("frame")) * Math.max(0.55, 1 - 0.12 * countType("balloon")) * (1 + 0.15 * countType("brick"));
      const inst = (g / L) * (0.35 + n * 0.12) * stab;
      const alpha = inst * Math.sin(S.theta) - (S.ax / L) * 0.3 * (1 + n * 0.06) * Math.cos(S.theta) - 2.7 * S.omega + S.wind * (0.4 + n * 0.06) / L;
      S.omega += alpha * dt; S.theta += S.omega * dt;
      if (Math.abs(S.theta) > S.tiltMax) { dropTop(Math.sign(S.theta)); S.theta = Math.sign(S.theta) * S.tiltMax * 0.55; S.omega *= -0.3; }
    } else { S.theta *= 0.9; S.omega = 0; }
    S.pitchV += (-S.pitch * 30 - S.pitchV * 6) * dt; S.pitch += S.pitchV * dt;
    // items may have fallen off above, so always read the live tower size
    const nt = S.tower.length;
    const share = nt ? 1 / nt : 0;
    for (let i = 0; i < nt; i++) {
      const l = S.tower[i].link;
      l.rotation.z = S.theta * share * (i === 0 ? 1.4 : 0.96);
      l.rotation.x = S.pitch * share * 0.6;
      if (l.userData.pop > 0) { l.userData.pop -= dt; l.scale.setScalar(1 + Math.max(0, l.userData.pop) * 1.75); }
    }

    const towerTop = new THREE.Vector3();
    const topItem = S.tower[S.tower.length - 1];
    if (topItem) { topItem.link.getWorldPosition(towerTop); towerTop.y += topItem.type.h * 0.5; }
    else towerTop.set(S.x, S.y + 1.6, S.z);

    S.droneTimer -= dt;
    if (-S.z > 220 && S.droneTimer <= 0) { addDrone(); S.droneTimer = 8 - hard * 4 + Math.random() * 3; }

    for (let i = things.length - 1; i >= 0; i--) {
      const t = things[i];
      if (t.kind === "pickup") {
        t.obj.rotation.y += dt * 2;
        t.obj.position.y = t.y + Math.sin(S.time * 3 + t.ph) * 0.12;
        const reach = 1.05 + 0.3 * P.level("magnet") + (countType("magnet") ? 0.9 : 0);
        if (reach > 1.1 && t.z < S.z + 1 && S.z - t.z < 7 && Math.abs(t.x - S.x) < reach * 1.7) {
          t.x += (S.x - t.x) * Math.min(1, dt * 5); t.obj.position.x = t.x;
        }
        if (Math.abs(t.z - S.z) < 0.95 + (reach - 1.05) * 0.4 && Math.abs(t.x - S.x) < reach && Math.abs(t.y - (S.y + 1)) < 1.7) {
          scene.remove(t.obj); things.splice(i, 1);
          addToTower(t.type);
          S.combo = S.comboT > 0 ? S.combo + 1 : 1; S.comboT = 2.6;
          if (S.combo >= 2) { S.pool += S.combo * 5; const c = $("combo"); c.classList.add("kick"); setTimeout(() => c.classList.remove("kick"), 120); }
          pop("+" + t.type.name + (t.type.tag ? " · " + t.type.tag : ""), t.type.tag ? "neon" : "good", new THREE.Vector3(S.x, S.y + 2.2, S.z));
          quest("items", 1); if (S.combo >= 2) quest("combo", S.combo);
          burst(new THREE.Vector3(t.x, t.y, t.z), 14, [0, 6, 2], 6, 0.12, 5, 0.6, 10);
          Audio.play("pickup", S.combo);
          continue;
        }
      } else if (t.kind === "obstacle") {
        if (!t.hit && Math.abs(t.z - S.z) < 0.75 && Math.abs(t.x - S.x) < t.hw + 0.3 && S.y < t.y + t.h - 0.1) {
          t.hit = true;
          if (S.dash > 0) {
            // ram through it
            things.push({ kind: "falling", obj: t.obj, vx: (t.x - S.x || 0.5) * 6, vy: 6, vz: -fwd * 0.9, spin: 8, t: 0 });
            things.splice(i, 1);
            burst(new THREE.Vector3(t.x, t.y + 0.6, t.z), 20, [5, 6, 1], 9, 0.18, 6, 0.8);
            S.pool += 15; S.shake = 0.35; S.omega += (Math.random() - 0.5) * 2.2;
            pop("Таран! +15", "neon", new THREE.Vector3(t.x, t.y + 2, t.z)); Audio.play("smash"); buzz(30); quest("rams", 1);
            continue;
          }
          stumble("Бум!"); S.omega += (S.x > t.x ? 1 : -1) * 1.6;
        }
      } else if (t.kind === "gate") {
        if (!t.used && S.z < t.z) {
          t.used = true;
          if (S.x < 0) bankTower(new THREE.Vector3(S.x, S.y + 2, S.z - 2));
          else if (S.tower.length) { pop("Рискуем! " + fmtMult(multiplier()), "neon"); S.pool += 20 * S.tower.length; }
        }
      } else if (t.kind === "drone") {
        t.t += dt;
        for (const r of t.rotors) r.rotation.y += dt * 30;
        t.obj.position.y = t.y + Math.sin(S.time * 2 + t.x) * 0.2;
        t.obj.lookAt(towerTop.x, t.obj.position.y, towerTop.z);
        const d = t.z - S.z;
        if (t.st === "idle" && -d < 26) { t.st = "aim"; t.t = 0; Audio.play("laser"); }
        if (t.st === "aim") {
          const a = t.obj.position, b = towerTop, len = a.distanceTo(b);
          t.laser.visible = Math.floor(t.t * 14) % 2 === 0;
          t.laser.position.copy(a).lerp(b, 0.5); t.laser.scale.set(0.06, len, 0.06);
          t.laser.lookAt(b); t.laser.rotateX(Math.PI / 2);
          t.eye.scale.setScalar(1.4 + t.t * 2);
          if (t.t > 0.8) {
            t.st = "fired"; t.laser.visible = false; t.eye.scale.setScalar(1.4);
            const bolt = new THREE.Mesh(SPH, M.bolt); bolt.scale.setScalar(0.35);
            const bg = new THREE.Sprite(M.glowSp(0xff3b5c)); bg.scale.setScalar(5); bolt.add(bg);
            bolt.position.copy(t.obj.position); scene.add(bolt);
            const aimAt = towerTop.clone(); aimAt.z -= S.speed * 0.22;
            const v = aimAt.sub(bolt.position).normalize().multiplyScalar(30);
            things.push({ kind: "bolt", obj: bolt, v, t: 0, near: false });
            Audio.play("bolt");
          }
        }
        if (d > 12) { scene.remove(t.obj); scene.remove(t.laser); things.splice(i, 1); continue; }
      } else if (t.kind === "bolt") {
        t.t += dt; t.obj.position.addScaledVector(t.v, dt);
        const dd = t.obj.position.distanceTo(towerTop);
        if (dd < 0.9) {
          scene.remove(t.obj); things.splice(i, 1);
          burst(t.obj.position, 16, [1, 6], 8, 0.14, 4, 0.5);
          if (S.tower.length) { dropTop(Math.sign(t.v.x) || 1); S.omega += (Math.sign(t.v.x) || 1) * 0.8; }
          else stumble("Попали!");
          continue;
        }
        if (dd < 2.2) t.near = true;
        if (t.near && dd > 2.2 && !t.nearPaid) { t.nearPaid = true; S.pool += 10; pop("Мимо! +10", "neon", towerTop); Audio.play("near"); quest("near", 1); }
        if (t.t > 2.5) { scene.remove(t.obj); things.splice(i, 1); continue; }
      } else if (t.kind === "falling") {
        t.t += dt; t.vy -= GRAV * 0.8 * dt;
        t.obj.position.x += t.vx * dt; t.obj.position.y += t.vy * dt; t.obj.position.z += t.vz * dt;
        t.obj.rotation.x += t.spin * dt; t.obj.rotation.z += t.spin * 0.7 * dt;
        if (t.t > 2.2) { scene.remove(t.obj); things.splice(i, 1); }
        continue;
      }
      if (t.z !== undefined && t.z - S.z > 14) { scene.remove(t.obj); if (t.laser) scene.remove(t.laser); things.splice(i, 1); }
    }

    while (S.genZ > S.z - 190) genNext();
    while (segs.length && segs[0].z1 - S.z > 30) { scene.remove(segs[0].group); segs.shift(); }

    // hero animation
    const moving = S.onGround;
    S.phase += dt * fwd * (moving ? 1.2 : 0);
    const sw = moving ? Math.sin(S.phase) * 0.95 : 0;
    hero.legs[0].rotation.x = moving ? sw : -0.6; hero.legs[1].rotation.x = moving ? -sw : 0.4;
    hero.arms[0].rotation.x = moving ? -sw * 0.9 : -2.6; hero.arms[1].rotation.x = moving ? sw * 0.9 : -2.6;
    hero.body.position.y = moving ? Math.abs(Math.cos(S.phase)) * 0.09 : 0;
    hero.body.rotation.z = -S.vx * 0.035 - S.theta * 0.15;
    hero.body.rotation.x = 0.14 + (S.dash > 0 ? 0.3 : 0) + (S.stumble > 0 ? 0.35 : 0);
    hero.root.position.set(S.x, S.y, S.z);
    S.rocketT = Math.max(0, S.rocketT - dt);
    hero.flame.visible = S.rocketT > 0 || S.dash > 0;
    hero.flame.scale.y = 0.45 + Math.random() * 0.3;
    hero.dashGlow.material.opacity = Math.max(0, S.dash) * 1.4;
    if (seg) { hero.blob.visible = true; hero.blob.position.set(S.x, seg.y + 0.02, S.z); const k = Math.max(0.3, 1 - (S.y - seg.y) / 6); hero.blob.scale.set(1.3 * k, k, 1); }
    else hero.blob.visible = false;

    if (state === "play" && !P.tutorialDone()) tutorial(dt, steer);
    updateCamera(dt, fwd);
    updateParticles(dt);
  }

  // ================================================================== first-run hints
  let tipTimer = null;
  function tip(text, dur) {
    const el = $("tip");
    el.textContent = text; el.hidden = false;
    clearTimeout(tipTimer);
    if (dur) tipTimer = setTimeout(() => (el.hidden = true), dur * 1000);
  }
  function hideTip() { $("tip").hidden = true; clearTimeout(tipTimer); }
  function tutorial(dt, steer) {
    const T = S.tut;
    T.t += dt;
    if (T.stage === 0) {
      if (T.t > 0.6 && T.t < 0.7) tip("Веди пальцем по левой половине экрана — бег влево-вправо");
      if (Math.abs(steer) > 0.4) T.steerT += dt;
      if (T.steerT > 0.7) { T.stage = 1; hideTip(); }
    } else if (T.stage === 1 && S.tower.length > 0) {
      T.stage = 2; tip("Вещи растут башней за спиной. Следи за шкалой крена и подбегай под башню", 5);
    }
    if (!T.gapTip && S.onGround && !segAt(S.z - 13) && segAt(S.z)) { T.gapTip = true; tip("Пропасть впереди — жми «Прыжок»!", 2.5); }
    if (!T.gateTip) {
      for (const t of things) if (t.gate && !t.used && t.z < S.z && S.z - t.z < 45) { T.gateTip = true; tip("Ворота! Беги в левый проход, чтобы сдать добычу в банк", 4); break; }
    }
  }

  function updateCamera(dt, fwd) {
    const th = Math.min(6, towerHeight());
    const cx = S.x * 0.55, cy = S.y + 4.2 + th * 0.35, cz = S.z + 7.8 + th * 0.45 + (S.dash > 0 ? 1.2 : 0);
    const k = Math.min(1, dt * 5);
    S.camX += (cx - S.camX) * k; S.camY += (cy - S.camY) * k * 0.8; S.camZ = cz;
    S.shake = Math.max(0, S.shake - dt);
    const sh = S.shake * S.shake * 1.6;
    camera.position.set(S.camX + (Math.random() - 0.5) * sh, S.camY + (Math.random() - 0.5) * sh, S.camZ);
    camera.lookAt(S.x * 0.35, S.y + 1.6 + th * 0.35, S.z - 7);
    camera.rotation.z += -S.vx * 0.006;
    S.fovKick = Math.max(0, S.fovKick - dt * 18);
    const portrait = window.innerWidth < window.innerHeight;
    const fov = (portrait ? 78 : 62) + Math.min(10, Math.max(0, fwd - 11) * 0.9) + S.fovKick;
    if (Math.abs(camera.fov - fov) > 0.05) { camera.fov += (fov - camera.fov) * Math.min(1, dt * 6); camera.updateProjectionMatrix(); }
    // world dressing follows
    sun.position.set(-24, 30, S.z - 200); sunCore.position.set(-24, 30, S.z - 199); sunCore.lookAt(camera.position);
    sunLight.position.set(S.x - 7, S.y + 14, S.z - 10); sunLight.target.position.set(S.x, S.y, S.z + 2);
    backdropGroup.position.z = Math.floor(S.z / 9) * 9;
    for (const c of clouds) c.position.set(c.userData.x, c.userData.y, S.z - 240 + ((c.userData.dz - S.z * 0.08) % 300 + 300) % 300 - 150);
    const sl = Math.min(1, Math.max(0, (fwd - 15) / 8) + (S.dash > 0 ? 0.7 : 0));
    M.speedLine.opacity = sl * 0.55;
    for (const l of speedLines) {
      l.userData.z = (l.userData.z + fwd * dt * 1.5) % 30;
      l.position.set(camera.position.x + Math.cos(l.userData.a) * l.userData.r, camera.position.y + Math.sin(l.userData.a) * l.userData.r * 0.7, camera.position.z - 30 + l.userData.z);
      l.visible = sl > 0.01;
    }
  }

  function stumble(text) {
    if (S.stumble > 0) return;
    S.stumble = 0.55; S.omega += (Math.random() < 0.5 ? -1 : 1) * 1.4; S.pitchV += 3; S.shake = 0.45;
    if (S.tower.length) dropTop();
    pop(text, "bad", new THREE.Vector3(S.x, S.y + 2.4, S.z));
    Audio.play("stumble"); buzz(60); flashVignette();
  }

  // ================================================================== flow and menus
  const show = (id, on) => { $(id).hidden = !on; };
  const SCREENS = ["startScreen", "garageScreen", "questScreen", "settingsScreen", "overScreen", "pauseScreen"];
  function only(id) { for (const sc of SCREENS) show(sc, sc === id); }
  const fmtStars = (n) => "★ " + n.toLocaleString("ru-RU");
  function refreshWallets() {
    const v = fmtStars(P.stars());
    for (const id of ["mWallet", "gWallet", "qWallet"]) setText(id, v);
    const u = P.unclaimed();
    $("questBadge").hidden = !u; $("questBadge").textContent = u;
    showBest();
  }
  function startRun() {
    resetRun();
    input.steer = 0; input.touchId = null; knob.style.transform = "";
    state = "play";
    only(null); show("hud", true); hideTip();
    $("muteBtn").textContent = Audio.musicOn() ? "♪ вкл" : "♪ выкл";
    try { Audio.start(); } catch (e) { console.error(e); }
    last = performance.now();
    try { navigator.wakeLock && navigator.wakeLock.request("screen").catch(() => {}); } catch (e) {}
  }
  function attract() { resetRun(); for (const id of ["crate", "lamp", "duck", "rocket"]) addToTower(TYPE[id]); }
  function toMenu() {
    if (state !== "menu") { state = "menu"; attract(); }
    show("hud", false); hideTip(); only("startScreen"); refreshWallets();
    Audio.stopMusic();
  }
  function gameOver(title, text) {
    if (state === "menu") { attract(); return; }
    state = "over";
    const dist = Math.round(-S.z);
    quest("dist", dist); quest("runs", 1);
    P.saveQuestProgress();
    const newBest = P.finishRun({ banked: S.bank, dist });
    $("overTitle").textContent = title; $("overText").textContent = text;
    $("oBank").textContent = "+" + S.bank; $("oDist").textContent = dist + " м";
    $("oWallet").textContent = fmtStars(P.stars()); $("oBest").textContent = fmtStars(P.get().best);
    $("newBest").hidden = !(newBest && S.bank > 0);
    const ql = $("overQuests"); ql.textContent = "";
    for (const q of S.questDone) { const d = document.createElement("div"); d.textContent = "✓ " + q + " — забери награду в «Заданиях»"; ql.appendChild(d); }
    show("hud", false); hideTip(); only("overScreen");
    Audio.stopMusic(); Audio.play("over"); buzz(120);
    $("againBtn").focus();
  }
  function togglePause() {
    if (state === "play") { state = "pause"; show("pauseScreen", true); Audio.stopMusic(); }
    else if (state === "pause") { state = "play"; show("pauseScreen", false); last = performance.now(); Audio.start(); }
  }

  // ---- garage
  let garageTab = "up";
  function openGarage() { if (state !== "menu") toMenu(); only("garageScreen"); renderGarage(); }
  function renderGarage() {
    refreshWallets();
    $("tabUp").classList.toggle("on", garageTab === "up"); $("tabSkins").classList.toggle("on", garageTab === "skins");
    $("upList").hidden = garageTab !== "up"; $("skinList").hidden = garageTab !== "skins";
    const ul = $("upList"); ul.textContent = "";
    for (const u of P.UPGRADES) {
      const lvl = P.level(u.id), cost = P.upgradeCost(u.id);
      const row = document.createElement("div"); row.className = "row-card";
      const info = document.createElement("div");
      const h = document.createElement("h3"); h.textContent = u.name;
      const p = document.createElement("p"); p.textContent = u.desc;
      const pips = document.createElement("div"); pips.className = "pips";
      for (let i = 0; i < u.max; i++) { const pi = document.createElement("i"); if (i < lvl) pi.className = "on"; pips.appendChild(pi); }
      info.append(h, p, pips);
      const btn = document.createElement("button"); btn.className = "buy";
      if (cost === null) { btn.textContent = "Максимум"; btn.disabled = true; }
      else {
        btn.textContent = "Улучшить · " + fmtStars(cost);
        if (P.stars() < cost) { btn.disabled = true; btn.title = "Не хватает звёзд"; }
        btn.addEventListener("click", () => { if (P.buyUpgrade(u.id)) { Audio.play("bank"); renderGarage(); } });
      }
      row.append(info, btn); ul.appendChild(row);
    }
    const sl = $("skinList"); sl.textContent = "";
    const cur = P.skin().id;
    for (const sk of P.SKINS) {
      const card = document.createElement("div"); card.className = "skin" + (sk.id === cur ? " cur" : "");
      const h = document.createElement("h3"); h.textContent = sk.name;
      const sw = document.createElement("div"); sw.className = "swatch";
      for (const c of [sk.body, sk.cap, sk.pants]) { const i = document.createElement("i"); i.style.background = "#" + c.toString(16).padStart(6, "0"); sw.appendChild(i); }
      const btn = document.createElement("button"); btn.className = "buy";
      if (sk.id === cur) { btn.textContent = "Надето"; btn.disabled = true; }
      else if (P.ownsSkin(sk.id)) { btn.textContent = "Надеть"; btn.classList.add("green"); btn.addEventListener("click", () => { P.equipSkin(sk.id); applySkin(P.skin()); renderGarage(); }); }
      else {
        btn.textContent = fmtStars(sk.cost);
        if (P.stars() < sk.cost) btn.disabled = true;
        btn.addEventListener("click", () => { if (P.buySkin(sk.id)) { applySkin(P.skin()); Audio.play("bank"); renderGarage(); } });
      }
      card.append(h, sw, btn); sl.appendChild(card);
    }
  }

  // ---- quests
  function openQuests() { if (state !== "menu") toMenu(); only("questScreen"); renderQuests(); }
  function renderQuests() {
    refreshWallets();
    const list = $("questList"); list.textContent = "";
    P.quests().forEach((q, i) => {
      const row = document.createElement("div"); row.className = "row-card";
      const info = document.createElement("div");
      const h = document.createElement("h3"); h.textContent = q.text;
      const p = document.createElement("p"); p.textContent = Math.min(q.progress, q.goal).toLocaleString("ru-RU") + " / " + q.goal.toLocaleString("ru-RU") + " · награда " + fmtStars(q.reward);
      const bar = document.createElement("div"); bar.className = "qbar";
      const fill = document.createElement("i"); fill.style.width = Math.round(100 * Math.min(1, q.progress / q.goal)) + "%"; bar.appendChild(fill);
      info.append(h, p, bar);
      const btn = document.createElement("button"); btn.className = "buy";
      if (q.claimed) { btn.textContent = "Получено"; btn.disabled = true; }
      else if (q.done) { btn.textContent = "Забрать " + fmtStars(q.reward); btn.classList.add("green"); btn.addEventListener("click", () => { if (P.claim(i)) { Audio.play("bank"); renderQuests(); } }); }
      else { btn.textContent = "В процессе"; btn.disabled = true; }
      row.append(info, btn); list.appendChild(row);
    });
  }

  // ---- settings
  function openSettings() { if (state !== "menu") toMenu(); only("settingsScreen"); renderSettings(); }
  function renderSettings() {
    const st = P.settings();
    document.querySelectorAll("#settingsScreen .seg").forEach((seg) => {
      const key = seg.dataset.set;
      seg.querySelectorAll("button").forEach((b) => {
        const v = b.dataset.v;
        const on = key === "quality" ? st.quality === v : String(st[key] ? 1 : 0) === v;
        b.classList.toggle("on", on);
      });
    });
    $("resetText").textContent = resetArmed ? "Точно? Всё будет потеряно." : "Звёзды, улучшения, образы и задания.";
    $("resetBtn").textContent = resetArmed ? "Да, сбросить" : "Сбросить";
  }
  let resetArmed = false;
  document.querySelectorAll("#settingsScreen .seg").forEach((seg) => {
    seg.addEventListener("click", (e) => {
      const b = e.target.closest("button"); if (!b) return;
      const key = seg.dataset.set, v = b.dataset.v;
      if (key === "music") Audio.setMusic(v === "1");
      else if (key === "sfx") Audio.setSfx(v === "1");
      else if (key === "vibro") { P.setSetting("vibro", v === "1"); if (v === "1") buzz(40); }
      else if (key === "quality") { P.setSetting("quality", v); applyQuality(v); }
      renderSettings();
    });
  });
  $("resetBtn").addEventListener("click", () => {
    if (!resetArmed) { resetArmed = true; renderSettings(); return; }
    resetArmed = false; P.reset(); applySkin(P.skin()); applyQuality(P.settings().quality); renderSettings(); refreshWallets();
  });

  window.gameBack = () => {
    if (state === "play") { togglePause(); return "paused"; }
    if (state === "pause" || state === "over") { toMenu(); return "menu"; }
    if (!$("startScreen").hidden) return "exit";
    toMenu(); return "menu";
  };
  $("startBtn").addEventListener("click", startRun);
  $("againBtn").addEventListener("click", startRun);
  $("garageRun").addEventListener("click", startRun);
  $("questRun").addEventListener("click", startRun);
  $("menuBtn").addEventListener("click", toMenu);
  $("garageBtn").addEventListener("click", openGarage);
  $("overGarage").addEventListener("click", openGarage);
  $("questBtn").addEventListener("click", openQuests);
  $("settingsBtn").addEventListener("click", openSettings);
  for (const id of ["garageBack", "questBack", "settingsBack"]) $(id).addEventListener("click", () => { resetArmed = false; toMenu(); });
  $("tabUp").addEventListener("click", () => { garageTab = "up"; renderGarage(); });
  $("tabSkins").addEventListener("click", () => { garageTab = "skins"; renderGarage(); });
  $("pauseBtn").addEventListener("click", togglePause);
  $("resumeBtn").addEventListener("click", togglePause);
  $("quitBtn").addEventListener("click", () => { state = "play"; gameOver("Забег окончен", "Сданное в банк засчитано."); });
  $("muteBtn").addEventListener("click", () => { Audio.setMusic(!Audio.musicOn()); if (Audio.musicOn()) Audio.start(); $("muteBtn").textContent = Audio.musicOn() ? "♪ вкл" : "♪ выкл"; });
  document.addEventListener("visibilitychange", () => { if (document.hidden && state === "play") togglePause(); });

  function resize() {
    const w = window.innerWidth, h = window.innerHeight;
    renderer.setSize(w, h, false); camera.aspect = w / h; camera.updateProjectionMatrix();
  }
  window.addEventListener("resize", resize);
  resize();

  // attract mode behind the menu: autopilot hero
  applySkin(P.skin());
  applyQuality(P.settings().quality);
  attract();
  refreshWallets();
  let last = performance.now();
  let loopErrors = 0;
  function frame(now) {
    requestAnimationFrame(frame);  // schedule first: one bad frame must never stop the game
    const dt = Math.min(0.05, (now - last) / 1000);
    last = now;
    try { tick(dt); } catch (e) {
      loopErrors++;
      console.error(e);
      if (loopErrors === 1 || loopErrors % 300 === 0) pop("Сбой: " + String(e && e.message || e).slice(0, 60), "bad");
    }
  }
  function tick(dt) {
    if (state === "play") { step(dt); updateHud(); }
    else if (state === "menu") {
      if (!segAt(S.z - 3.4) && S.onGround) S.jumpBuf = 0.1;
      input.steer = Math.sin(S.time * 0.7) * 0.15 - S.theta * 1.5;
      const keep = S.tower.length;
      step(dt * 0.6);
      if (S.tower.length < keep) addToTower(pickRandomType());
    } else updateParticles(dt * 0.3);
    renderer.render(scene, camera);
  }
  // automated smoke test used by the APK build (index.html#autotest)
  if (location.hash === "#autotest") {
    const errs = [];
    window.addEventListener("error", (e) => errs.push(String(e.message)));
    setTimeout(() => {
      startRun();
      let k = 0;
      const iv = setInterval(() => { k++; input.steer = Math.sin(k * 0.3); if (k % 7 === 0) requestJump(); if (k % 23 === 0) requestDash(); }, 100);
      setTimeout(() => {
        clearInterval(iv);
        document.title = (errs.length ? "AUTOTEST_FAIL " + errs.join(" | ") : "AUTOTEST_OK") +
          " state=" + state + " dist=" + Math.round(-S.z) + " tower=" + S.tower.length + " segs=" + segs.length + " things=" + things.length;
      }, 6000);
    }, 500);
  }
  window.__TR = { S, input, things, step: (dt) => step(dt), state: () => state, segAt, requestJump, requestDash, P };
  const boot = () => requestAnimationFrame(frame);
  if (window.claude?.hot?.ready) window.claude.hot.ready(boot); else boot(window.claude?.hot?.data ?? {});
})();
