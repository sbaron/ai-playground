# Solar System Explorer — build notes

Interactive 3D orrery built to the spec in [`AGENTS.md`](./AGENTS.md): a single
self-contained HTML file, Three.js + vanilla JS, procedural visuals only (no image assets).

---

## 1 · Model & environment specification

| Field | Value |
|---|---|
| Model id | `strata-qwen3.8-flash-next-iq4` |
| Provider | `llama-cpp` (local inference) |
| Reasoning level | `off` |
| Harness | [pi](https://github.com/badlogic/pi-mono) coding-agent, release `1.5.0` |
| Session id | `01a1aab8-0864-75d0-9406-1b0dc5542fd1` |
| Session file | `~/.pi/agent/sessions/--home-seb-src-test--/2026-11-05T07-59-09-925Z_01a1aab8-….jsonl` |
| Runtime tools | Node v22.23.2, Python 3.14.9, Google Chrome 157 (headless + SwiftShader) |
| Working directory | `/home/seb/src/test` |

## 2 · Date & time of implementation

All times on **Thursday 2026-11-05** (CET, UTC+01:00):

| Milestone | Local (CET) | UTC |
|---|---|---|
| Session opened | 08:59:09 | 07:59:09 |
| First working build (boot, planets, UI) | ~09:20 – 09:50 | ~08:20 – 08:50 |
| Headless verification + tuning passes | 09:50 – 10:45 | 08:50 – 09:45 |
| `index.html` written (v1) | 10:49:06 | 09:49:06 |
| Screenshot review (`Screenshot 2026-11-05 12.56.13.png`) | 11:50 – 12:56 | 10:50 – 11:56 |
| Visual pass: Earth geography, city lights, ring shadow, corona depth | 13:05 – 14:20 | 12:05 – 13:20 |
| This README updated | 14:25 | 13:25 |

---

## 3 · Deliverable

```
index.html   90 050 bytes · 1 715 lines · 0 image assets · 0 build step
```

Only two network dependencies: `three@0.160.0` (jsDelivr ESM via import map, including
`OrbitControls`, `EffectComposer`, `RenderPass`, `UnrealBloomPass`, `OutputPass`) and Google
Fonts (Inter + JetBrains Mono, which degrade silently to the system stack offline). A
12-second watchdog shows a friendly banner if the CDN is unreachable.

```bash
python3 -m http.server 8000     # ES modules must be served over http://, file:// will not work
```

## 4 · Scale model

Orbital radii are squeezed logarithmically and body radii by √, so Mercury and Neptune (and
Mercury's 4 879 km vs Jupiter's 139 820 km) can share one screen while keeping the *ordering*
and sense of proportion honest.

```
orbit  = 12 + 26 · log10(1 + 1.5 · AU)      radius = 0.90 · √(km / 6371)      (Sun: fixed 5.5)
```

| Body | radius (units) | orbit (units) | real diameter | real period | spin @1× (rad/s) |
|---|---|---|---|---|---|
| Sun | 5.50 *(not to scale)* | 0 | 1 391 400 km | — | 0.011 |
| Mercury | 0.557 | 17.17 | 4 879 km | 88.0 d | +0.011 |
| Venus | 0.877 | 20.29 | 12 104 km | 224.7 d | −0.003 (retro) |
| Earth | 0.900 | 22.35 | 12 742 km | 365.3 d | +0.63 |
| Moon | 0.197 | 1.98 (of Earth) | 3 475 km | 27.3 d | tidally locked |
| Mars | 0.656 | 25.43 | 6 779 km | 687.0 d | +0.61 |
| Jupiter | 2.981 | 36.56 | 139 820 km | 4 332.6 d | +1.52 |
| Saturn | 2.721 | 42.81 | 116 460 km | 10 759 d | +1.42 |
| Uranus | 1.796 | 50.32 | 50 724 km | 30 688 d | −0.88 (retro) |
| Neptune | 1.769 | 55.26 | 49 244 km | 60 182 d | +0.94 |
| Belt | — | 28.07 – 31.99 | 2.1 – 3.25 AU | Keplerised | — |

* **Time base:** 1× = 10 simulated days per real second → Mercury year 8.8 s, Earth year 36.5 s,
  Neptune year ~100 min. Slider covers 0.1×–10×.
* **Rotation is compressed separately** (`ROT_SCALE = 0.010`) — at true ratio the planets would
  be motion blur; relative direction and speed order are preserved, including Venus/Uranus
  retrograde spin.
* Real orbital **inclination + ascending node** are applied to both the orbit lines and the
  planet positions, so the system is not a flat coin.

## 5 · How the visuals are made (no external media)

* **Noise** — seeded lattice value-noise (`mulberry32` → lattice → smoothstep bilinear), fBm with
  integer frequencies so every texture wraps seamlessly around the sphere.
* **Rocky bodies** (Mercury, Moon, Mars) — fBm albedo ramp + *analytic* crater field (bowl +
  rim uplift, latitude-corrected) written into both the colour map and a matching bump map.
  The Moon adds dark `mare` patches; Mars adds noisy polar caps.
* **Earth** — a hand-authored **landmask**: ~20 equirectangular `[lon,lat]` outlines (Africa,
  Eurasia, both Americas, Australia, Greenland, Antarctica, Madagascar, Japan, NZ, the Sunda
  islands…) filled into a 720 × 360 grid with an even-odd point-in-polygon test, inland seas
  (Hudson Bay, Black Sea, Caspian, Baltic, Carpentaria) carved back out, then wrapped box-blurred.
  fBm is added on top of that field so coastlines come out ragged instead of polygonal. From the
  same field: turquoise **shelves**, a **desert belt** at 14–38° latitude, boreal/green zonation,
  orographic rock + snow, and ice caps over both ocean and land past ~73°. A **roughness map**
  (ocean 0.18 / land 0.82) confines the sun glint to water. Clouds live on their own shell
  (drifting 1.35× faster) whose *opacity* — not coverage — is modulated by ITCZ / polar-front /
  subtropical-dry belts. A third shell, additive and parented to the spin, draws **city lights**:
  clusters that avoid ice, deserts and the deep interior, faded in by `-dot(N, sunDir)` so they
  only appear on the night side and brighten toward the terminator.
* **Gas/ice giants** — latitude bands from `sin(v·bands + warped fBm)`, Jupiter gets a swirling
  Great Red Spot, Saturn/Uranus banded softer; poles are tinted.
* **Rings** — 1 024 × 1 banded-alpha strip (Cassini-like divisions), UVs remapped radially on a
  `RingGeometry`; Saturn bright, Uranus dark and near-vertical thanks to its 97.8° tilt. The ring
  material is a 20-line shader instead of `MeshBasicMaterial`: for every fragment it tests whether
  the ray toward the Sun passes within one planetary radius of the planet's centre, which paints
  the planet's **shadow across the rings** (and darkens the sheet that is in front of the Sun),
  plus a forward-scattering term so the rings brighten when the Sun is behind them.
* **Atmospheres** — one small `ShaderMaterial` reused for 7 bodies: Fresnel rim on a back-side
  shell, modulated by the dot product with the Sun (which sits at the origin, so no uniforms
  need updating) → crescent glow that dies on the night side.
* **Sky** — 8 570 stars in 3 additive layers with blackbody-ish tints, plus a transparent
  Milky-Way band (fbm clouds × dust lanes × Gaussian band) on a 4 200-unit sphere.
* **Post** — `RenderPass → UnrealBloomPass → OutputPass`, ACES Filmic tone mapping.

## 6 · Lighting / grading tuning log

Values that were found by measurement rather than by eye:

| Knob | Value | Why |
|---|---|---|
| `PointLight.intensity` | 1.95, `decay 0` | decay 0 keeps Neptune as readable as Mercury; 1.95 sits just under clipping for cloud/ice |
| `toneMappingExposure` | 1.02 | ACES desaturates dark albedos, so the day side needed a nudge rather than a brighter ocean map |
| Bloom strength / radius / threshold | 0.32 / 0.35 / **1.0** | threshold >1 means *only* the Sun (and specular sparkles) blooms, so lit planets don't wash the frame |
| Bloom resolution | 0.66 × viewport | ~40 % of the blur cost, invisible quality loss |
| `setClearColor` | `0x000000` | ACES lifts shadows — `0x03040a` produced a `(9,13,36)` full-screen haze |
| Corona sprites | 2.6×/4.4×/7.2× R at 0.30/0.085/0.016, **`depthTest: true`** | with `depthTest: false` the additive halo painted *in front of* foreground worlds: the reviewed screenshot measured mean L 60 and 36 % warm pixels in the sky next to Earth; after the fix the same framing measures ~6 with ~5 % |
| Ocean ramp | deep stop `(12,40,108)` at depth 0.42 | deep water was keying to the darkest stop, so the disc averaged `93,93,81` (warm). Remapping the ramp put open ocean on the mid stop: the lit disc now averages `104,118,132` |
| Cloud belts | ×(0.52 + ITCZ + front − dry) on **alpha** | first attempt scaled the fBm *past* the coverage threshold → 85 % of probes read as bright neutral (snowball Earth) |
| City-light `uIntensity` | 5.0, clamped at α 1.35 | measured boost of night-side pixels: ≈59 mean at α 1.35, unclamped it clipped to 255 |

## 7 · Verification (headless Chrome over CDP)

Chrome 157 + SwiftShader was driven with `puppeteer-core` (scripts kept in `/tmp/pw/`,
not part of the deliverable). Since the assistant here has no image input, every check reads
**pixels and scene state numerically** out of the live renderer:

* **Boot** 3.6–4.4 s software-rendered, loader fades, `0` console/page errors, 35 textures /
  47 geometries / 20 programs, 10 labels, 11 dropdown entries, 4 point clouds.
* **Colour audit** — focus each body, sample its disc, terminator and off-limb space:
  Mercury `119,107,91` grey · Venus `182,154,99` cream · Earth `114,113,102` (ocean/land/cloud mix)
  Mars `140,59,29` rust · Jupiter `155,124,92` tan · Saturn `185,167,130` gold with rings at
  `200,193,176` and black past the ring edge · Uranus `151,176,172` cyan · Neptune `67,94,147`
  deep blue · Sun `255,226,143`. Off-limb space measures `0,0,2 … 10,9,7` → no veiling. 0 problems.
* **Geographic survey** — the decisive Earth check: for each of 264 (lon, lat) samples the globe is
  rotated so the sample sits at the sub-solar point, the camera is offset 43° off the mirror angle
  (so glossy ocean doesn't read as sun glint), and the *rendered* pixel is classified. Result: the
  desert belt lands at lon 30→120 / lat 30 (Sahara · Arabia · Iran · Thar · Gobi), the Amazon and
  Congo basins read green, Namib/Atacama-outback deserts at lat −30, Southern Ocean reads `~`,
  Greenland and Antarctica read ice, the Sunda shelves read turquoise. 130/264 samples classify
  blue, 24 warm; the disc mean is `104,118,132` → blue-dominant. Prototype of the mask was
  ASCII-printed at 120 × 50 and probed against 35 known places before being wired in (London,
  Tokyo, Rio, Cape Town, Jakarta, mid-Pacific, Hudson Bay, Black Sea, Caspian…).
* **Ring shadow A/B** — with the shader's `uBodyR` forced to 0 (shadow off) versus on: 12 989 ring
  pixels darken by >12 levels (mean 15.5, max 193) in a band consistent with the planet silhouette.
* **City lights A/B** — `uIntensity` 0 → 25 boosts 63 449 night-side disc pixels by 59 on average.
* **Sun profile** — radial luminance from the photosphere outward: `191 … 191` across the disc,
  then `60 → 47 → 35 → 29 → 23 → 18 → 11 → 6 → 2` over the corona, i.e. a smooth halo with no
  ring artefact at the limb.
* **Motion** — 1× advances 10 d/s; Mercury moves 3.25 units in 1.5 s vs Neptune 0.02 (correct
  ordering); pause freezes positions *and* `state.days`.
* **Camera** — focus converges then rigidly follows (cam↔Saturn 18.65 → 18.65 units while the
  planet travels); `Esc`, `R`, `1…8`, `[`, `]`, `Space` all behave; speed readout, chip and
  `--fill` track together.
* **Picking** — click each projected disc: 8/10 exact; the two "misses" are true depth
  occlusion (a 2 px Moon passing in front of Earth, Saturn aligned behind Jupiter).
* **Touch & mobile** — 390 × 780: no horizontal overflow, bottom-sheet card, deck fits,
  `touchscreen.tap` opens the correct card, labels outside the frustum hidden.
* Also rendered ASCII luminance/hue maps of the frame to sanity-check composition, which is how
  the backlit-framing and sky-lift bugs were spotted in the first place.

### Bugs the verification loop caught

1. `BufferGeometry.applyAxisAngle` does not exist → orbit lines crashed boot. Now
   `applyMatrix4(makeRotationAxis(...))`.
2. Focus framing placed the camera **anti-sunward**, so every planet was a backlit silhouette
   inside the Sun's glare. The camera now sits sunward (`_dir = -normalize(planetPos)`, plus
   elevation), giving a lit disc with a graceful terminator.
3. `setClearColor(0x03040a)` + ACES = milky sky everywhere.
4. Invisible hit spheres were clamped at 0.85 units → the Moon's picking bubble was 4.3× its
   disc and stole Earth clicks. Now `max(r·1.5, 0.5)`, and the Sun's sphere is exactly its disc.
5. Labels could be positioned at `±9 000 000 px` and, being merely `opacity:0`, stayed clickable.
   Projection is now guarded (camera-space half-space + finite + NDC bounds) and hidden labels
   get `pointer-events:none`.
6. *(from the screenshot review)* The corona sprites were additive with **`depthTest: false`**, so
   the warm halo drew on top of everything in front of it — that is the milky warm quadrant in the
   top right of the reviewed screenshot, and the reason a foreground planet looked veiled. They now
   depth-test against the scene, so the Sun can only glow where nothing is in front of it.
7. Earth's continents were pure fBm, so the planet read as "an Earth-coloured marble" rather than
   Earth. Replaced with the authored landmask described in §5.
8. First cloud-belt edit multiplied the fBm *up* through its coverage threshold instead of scaling
   the resulting alpha, turning the planet into a snowball (85 % of survey probes read bright
   neutral). Belts now scale alpha only; coverage went back to ~⅓.
9. Test-harness bugs worth remembering: reading back the WebGL canvas after `requestAnimationFrame`
   can return a cleared buffer (use `setTimeout` waits), and a camera parked on the Sun→planet axis
   measures the ocean's specular glint instead of its colour.

## 8 · Known limits & knobs

* Perf on a real GPU is comfortably 60 fps; under pure software rasterisation the same scene is
  ~17 fps, which is exactly what the built-in adaptive step (drops pixel ratio twice if fps < 40)
  is there for. `Glow` and `Belt` toggles are the manual escape hatches.
* `DAYS_PER_SECOND`, `ROT_SCALE`, `radiusScale`, `distScale` at the top of the module are the
  single knobs for the whole scale/time model.
* Saturn's rings are shadowed analytically (planet → rings) without shadow maps; eclipses of a
  moon by its planet, and ring shadows *onto* the planet, are still absent — the latter would need
  a custom planet shader and would cost the PBR roughness response.
* Coastlines are ~0.5° outlines hand-fitted from memory of the world map, so they are recognisable
  rather than survey-accurate (no Mediterranean bathymetry, no Caribbean, one blob per island).
* `window.__solar` exposes `scene / camera / controls / state / follow / planetRigs / focusOn …`
  for live poking from the console.
* Texture generation is chunked across animation frames so the loading screen shows real
  progress instead of a frozen tab.
