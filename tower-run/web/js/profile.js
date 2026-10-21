/* Player profile: currency, upgrades, skins, daily quests, settings. Saved in localStorage. */
(function () {
  "use strict";
  const KEY = "tower-profile-v1";

  const UPGRADES = [
    { id: "frame", name: "Каркас рюкзака", desc: "Башню качает меньше, она держит больший крен", max: 5, costs: [150, 400, 900, 1800, 3500] },
    { id: "legs", name: "Пружинные кроссовки", desc: "Прыжок выше, даже с тяжёлой башней", max: 5, costs: [120, 350, 800, 1600, 3200] },
    { id: "dash", name: "Турбо-рывок", desc: "Рывок перезаряжается быстрее и длится дольше", max: 5, costs: [150, 400, 900, 1800, 3500] },
    { id: "magnet", name: "Магнитные перчатки", desc: "Вещи притягиваются с соседней полосы", max: 5, costs: [200, 500, 1100, 2200, 4000] },
    { id: "insurance", name: "Страховка", desc: "Ловит падающую вещь: один раз за забег на уровень", max: 3, costs: [600, 1800, 4500] },
  ];

  const SKINS = [
    { id: "classic", name: "Классика", cost: 0, body: 0xec7634, pants: 0x34406a, cap: 0x2c966e, capD: 0x1f6f51, skin: 0xf3cba2 },
    { id: "ninja", name: "Ниндзя", cost: 500, body: 0x2e2a36, pants: 0x1c1a22, cap: 0xd8483e, capD: 0x9a2a24, skin: 0xf3cba2 },
    { id: "cosmo", name: "Космонавт", cost: 900, body: 0xf2f2f4, pants: 0x9aa6c0, cap: 0x3c6ec8, capD: 0x2a4c8c, skin: 0xe8b88f },
    { id: "pirate", name: "Пират", cost: 1200, body: 0xc33a3a, pants: 0x2a2632, cap: 0x1c1a22, capD: 0xf0c446, skin: 0xd9a074 },
    { id: "neon", name: "Неон", cost: 2500, body: 0x56e0ff, pants: 0x6b4bc4, cap: 0xe0447a, capD: 0xffd646, skin: 0xf3cba2 },
    { id: "gold", name: "Золотой", cost: 6000, body: 0xf0c446, pants: 0xb88a20, cap: 0xfff0b0, capD: 0xd0a030, skin: 0xf3cba2 },
  ];

  // mode "max": best value within one run counts; "sum": adds up over the day
  const QUESTS = [
    { id: "dist", text: (n) => `Пробеги ${n} м за один забег`, goals: [600, 1000, 1600], reward: [100, 180, 300], mode: "max" },
    { id: "bigbank", text: (n) => `Сдай за раз башню из ${n}+ вещей`, goals: [5, 8, 12], reward: [120, 200, 320], mode: "max" },
    { id: "banktotal", text: (n) => `Сдай в банк ${n} ★ за день`, goals: [600, 1500, 3000], reward: [100, 180, 300], mode: "sum" },
    { id: "rams", text: (n) => `Протарань рывком ${n} препятствий`, goals: [3, 6, 10], reward: [100, 170, 260], mode: "sum" },
    { id: "near", text: (n) => `Увернись от ${n} выстрелов дронов`, goals: [2, 4, 7], reward: [110, 190, 300], mode: "sum" },
    { id: "items", text: (n) => `Собери ${n} вещей`, goals: [30, 60, 100], reward: [90, 160, 250], mode: "sum" },
    { id: "combo", text: (n) => `Сделай комбо ×${n}`, goals: [4, 6, 8], reward: [100, 170, 260], mode: "max" },
    { id: "runs", text: (n) => `Сыграй ${n} забега`, goals: [3, 5, 8], reward: [80, 140, 220], mode: "sum" },
  ];

  const DEFAULT = () => ({
    v: 1, stars: 0, best: 0, bestDist: 0, runs: 0, totalBanked: 0,
    up: { frame: 0, legs: 0, dash: 0, magnet: 0, insurance: 0 },
    skins: ["classic"], skin: "classic",
    quests: { day: "", list: [] },
    settings: { music: true, sfx: true, vibro: true, quality: "high" },
    tutorialDone: false,
  });

  let data = DEFAULT();
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) data = Object.assign(DEFAULT(), JSON.parse(raw));
    // carry over the record from the first prototype
    const oldBest = parseInt(localStorage.getItem("tower-best") || "0", 10) || 0;
    if (oldBest > data.best) data.best = oldBest;
    if (localStorage.getItem("tower-muted") === "1" && !raw) data.settings.music = false;
  } catch (e) {}
  data.up = Object.assign(DEFAULT().up, data.up);
  data.settings = Object.assign(DEFAULT().settings, data.settings);

  function save() { try { localStorage.setItem(KEY, JSON.stringify(data)); } catch (e) {} }

  function today() {
    const d = new Date();
    return d.getFullYear() + "-" + (d.getMonth() + 1) + "-" + d.getDate();
  }
  function seeded(seedStr) {
    let h = 2166136261;
    for (let i = 0; i < seedStr.length; i++) { h ^= seedStr.charCodeAt(i); h = Math.imul(h, 16777619); }
    return () => { h ^= h << 13; h ^= h >>> 17; h ^= h << 5; return ((h >>> 0) % 100000) / 100000; };
  }
  function ensureQuests() {
    const day = today();
    if (data.quests.day === day && data.quests.list.length) return;
    const rnd = seeded(day);
    const pool = QUESTS.slice();
    const list = [];
    for (let i = 0; i < 3; i++) {
      const q = pool.splice(Math.floor(rnd() * pool.length), 1)[0];
      const tier = Math.min(2, Math.floor(rnd() * 3));
      list.push({ id: q.id, tier, goal: q.goals[tier], reward: q.reward[tier], progress: 0, done: false, claimed: false });
    }
    data.quests = { day, list };
    save();
  }
  const questDef = (id) => QUESTS.find((q) => q.id === id);

  const P = {
    UPGRADES, SKINS,
    get: () => data,
    save,
    stars: () => data.stars,
    level: (id) => data.up[id] || 0,
    upgradeCost(id) {
      const u = UPGRADES.find((x) => x.id === id);
      const lvl = data.up[id] || 0;
      return lvl >= u.max ? null : u.costs[lvl];
    },
    buyUpgrade(id) {
      const c = P.upgradeCost(id);
      if (c === null || data.stars < c) return false;
      data.stars -= c; data.up[id] = (data.up[id] || 0) + 1; save(); return true;
    },
    skin: () => SKINS.find((s) => s.id === data.skin) || SKINS[0],
    ownsSkin: (id) => data.skins.includes(id),
    buySkin(id) {
      const s = SKINS.find((x) => x.id === id);
      if (!s || P.ownsSkin(id)) return false;
      if (data.stars < s.cost) return false;
      data.stars -= s.cost; data.skins.push(id); data.skin = id; save(); return true;
    },
    equipSkin(id) { if (P.ownsSkin(id)) { data.skin = id; save(); return true; } return false; },
    addStars(n) { data.stars += n; save(); },
    finishRun({ banked, dist }) {
      data.runs++; data.totalBanked += banked; data.stars += banked;
      const newBest = banked > data.best;
      if (newBest) data.best = banked;
      if (dist > data.bestDist) data.bestDist = dist;
      save();
      return newBest;
    },
    quests() { ensureQuests(); return data.quests.list.map((q) => Object.assign({ text: questDef(q.id).text(q.goal) }, q)); },
    unclaimed() { ensureQuests(); return data.quests.list.filter((q) => q.done && !q.claimed).length; },
    /** Report progress. Returns texts of quests completed by this event. */
    questEvent(id, value) {
      ensureQuests();
      const done = [];
      for (const q of data.quests.list) {
        if (q.id !== id || q.done) continue;
        const def = questDef(id);
        q.progress = def.mode === "max" ? Math.max(q.progress, value) : q.progress + value;
        if (q.progress >= q.goal) { q.progress = q.goal; q.done = true; done.push(def.text(q.goal)); }
      }
      if (done.length) save();
      return done;
    },
    saveQuestProgress() { save(); },
    claim(i) {
      const q = data.quests.list[i];
      if (!q || !q.done || q.claimed) return 0;
      q.claimed = true; data.stars += q.reward; save(); return q.reward;
    },
    settings: () => data.settings,
    setSetting(k, v) { data.settings[k] = v; save(); },
    tutorialDone: () => data.tutorialDone,
    finishTutorial() { data.tutorialDone = true; save(); },
    reset() { data = DEFAULT(); save(); },
  };
  window.TowerProfile = P;
})();
