package com.tigirer.sonfener.core;

import com.tigirer.sonfener.core.LevelDef.SpawnRule;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Bir gecenin tüm oyun mantığı. Android'e bağımlı değildir; JVM'de test edilebilir.
 * Koordinatlar fenere göre, y aşağı doğru; ekran genişliği 1000 birimdir.
 */
public final class World {

    public enum State {PLAYING, WON, LOST}

    public interface Listener {
        void onKill(Shadow s);

        void onLanternHit(float damage);

        void onFlash();

        void onBossSpawn(Shadow boss);

        void onOverheat();

        void onDawn();
    }

    public static final float HALF_W = 500f;
    public static final float LANTERN_R = 42f;
    public static final float BEAM_RANGE = 620f;
    public static final float FLASH_RADIUS = 440f;
    /** Işının saniyedeki azami dönüş hızı (radyan). */
    public static final float TURN_SPEED = 10f;
    /** Işıkta olan gölgenin hız çarpanı. */
    public static final float LIT_SLOW = 0.55f;
    /** Aşırı ısınmadan sonra ışın, enerji bu orana gelince tekrar açılır. */
    public static final float RECOVER_FRACTION = 0.35f;
    /** Işın açıkken saniyedeki enerji tüketimi. */
    public static final float BEAM_DRAIN = 24f;

    public final float halfH;
    public final Upgrades up;
    public final LevelDef level;
    public final List<Shadow> shadows = new ArrayList<>();
    private final List<Shadow> pending = new ArrayList<>();
    private final float[] nextSpawn;
    private final Random rng;
    private Listener listener;

    public State state = State.PLAYING;
    public float time;
    public float oil;
    public float energy;
    public float flashCd;
    public float flashFx;
    public float beamAngle = (float) (-Math.PI / 2);
    public boolean beamOn;
    public boolean overheated;
    public int kills;
    public int sparks;
    public Shadow boss;
    public boolean bossSpawned;
    public boolean bossDefeated;
    public int bossCount;

    private boolean beamWanted;
    private float beamTarget = beamAngle;
    private float endlessNext;

    public World(LevelDef level, Upgrades up, float aspect, long seed) {
        this.level = level;
        this.up = up;
        this.halfH = HALF_W * Math.max(1.2f, aspect);
        this.rng = new Random(seed);
        this.oil = up.maxOil();
        this.energy = up.maxEnergy();
        this.nextSpawn = new float[level.rules.length];
        for (int i = 0; i < nextSpawn.length; i++) nextSpawn[i] = level.rules[i].start;
        this.endlessNext = 1.5f;
    }

    public void setListener(Listener l) {
        this.listener = l;
    }

    /** Parmak ekrandayken true; hedef açı parmağın fenere göre yönüdür. */
    public void setBeam(boolean wanted, float targetAngle) {
        this.beamWanted = wanted;
        if (wanted) this.beamTarget = targetAngle;
    }

    public boolean flash() {
        if (state != State.PLAYING || flashCd > 0f) return false;
        flashCd = up.flashCooldown();
        flashFx = 0.5f;
        for (Shadow s : shadows) {
            float d = s.dist();
            if (d - s.type.radius > FLASH_RADIUS) continue;
            s.hp -= up.flashDamage();
            s.hurt = 0.25f;
            float push = s.type.isBoss() ? 30f : 150f;
            if (d > 1f) {
                s.x += s.x / d * push;
                s.y += s.y / d * push;
            }
        }
        if (listener != null) listener.onFlash();
        return true;
    }

    /** Oyuncu geceyi bırakır (Sonsuz Gece'de "bitir"). */
    public void forfeit() {
        if (state != State.PLAYING) return;
        state = State.LOST;
        beamOn = false;
    }

    public void update(float dt) {
        if (state != State.PLAYING) return;
        time += dt;
        if (flashCd > 0f) flashCd = Math.max(0f, flashCd - dt);
        if (flashFx > 0f) flashFx = Math.max(0f, flashFx - dt);

        updateBeam(dt);
        spawn();
        updateShadows(dt);
        cleanup();
        checkEnd();
    }

    // ---------------------------------------------------------------- ışın

    private void updateBeam(float dt) {
        float diff = wrap(beamTarget - beamAngle);
        float step = TURN_SPEED * dt;
        beamAngle = wrap(beamAngle + Math.max(-step, Math.min(step, diff)));

        float maxE = up.maxEnergy();
        if (overheated && energy >= maxE * RECOVER_FRACTION) overheated = false;
        beamOn = beamWanted && !overheated && energy > 0f;
        if (beamOn) {
            energy -= BEAM_DRAIN * dt;
            if (energy <= 0f) {
                energy = 0f;
                overheated = true;
                beamOn = false;
                if (listener != null) listener.onOverheat();
            }
        } else {
            energy = Math.min(maxE, energy + up.regen() * dt);
        }
    }

    // ------------------------------------------------------------- doğurma

    private void spawn() {
        if (level.endless) {
            spawnEndless();
            return;
        }
        for (int i = 0; i < level.rules.length; i++) {
            SpawnRule r = level.rules[i];
            if (time < nextSpawn[i] || time > r.end) continue;
            for (int g = 0; g < r.group; g++) spawnAtEdge(r.type, 1f);
            float p = (time - r.start) / Math.max(0.01f, r.end - r.start);
            float interval = r.i0 + (r.i1 - r.i0) * Math.min(1f, p);
            nextSpawn[i] = time + interval * (0.8f + 0.4f * rng.nextFloat());
        }
        if (level.boss != null && !bossSpawned && time >= level.bossAt) spawnBoss(1f);
    }

    private void spawnEndless() {
        if (time >= endlessNext) {
            float t = time;
            float roll = rng.nextFloat();
            ShadowType type = ShadowType.CRAWLER;
            if (t > 20f && roll > 0.55f) type = ShadowType.RUNNER;
            if (t > 40f && roll > 0.78f) type = ShadowType.SPLITTER;
            if (t > 60f && roll > 0.90f) type = ShadowType.ARMORED;
            float hpScale = 1f + t / 240f;
            spawnAtEdge(type, hpScale);
            if (t > 90f && rng.nextFloat() < 0.35f) spawnAtEdge(ShadowType.CRAWLER, hpScale);
            float interval = Math.max(0.45f, 2.0f - t * 0.011f);
            endlessNext = time + interval * (0.8f + 0.4f * rng.nextFloat());
        }
        if (boss == null && time >= 60f + bossCount * 75f) {
            spawnBoss(1f + 0.5f * bossCount);
        }
    }

    private void spawnBoss(float hpScale) {
        ShadowType t = level.endless && bossCount % 2 == 1 ? ShadowType.MOTHER
                : (level.endless ? ShadowType.CAPTAIN : level.boss);
        boss = spawnAtEdge(t, hpScale);
        bossSpawned = true;
        bossCount++;
        if (listener != null) listener.onBossSpawn(boss);
    }

    private Shadow spawnAtEdge(ShadowType type, float hpScale) {
        float a = rng.nextFloat() * (float) (Math.PI * 2);
        float c = (float) Math.cos(a), s = (float) Math.sin(a);
        float margin = type.radius + 40f;
        float tx = Math.abs(c) < 1e-4f ? Float.MAX_VALUE : (HALF_W + margin) / Math.abs(c);
        float ty = Math.abs(s) < 1e-4f ? Float.MAX_VALUE : (halfH + margin) / Math.abs(s);
        float t = Math.min(tx, ty);
        Shadow sh = new Shadow(type, c * t, s * t, hpScale, rng.nextFloat() * 6.283f);
        shadows.add(sh);
        return sh;
    }

    private void spawnAround(ShadowType type, float cx, float cy, float spread) {
        float a = rng.nextFloat() * 6.283f;
        Shadow sh = new Shadow(type, cx + (float) Math.cos(a) * spread, cy + (float) Math.sin(a) * spread,
                1f, rng.nextFloat() * 6.283f);
        pending.add(sh);
    }

    // ------------------------------------------------------------ gölgeler

    private void updateShadows(float dt) {
        float dps = up.beamDps();
        float half = up.beamHalfAngle();
        for (Shadow s : shadows) {
            s.age += dt;
            if (s.hurt > 0f) s.hurt -= dt;
            float d = s.dist();

            s.lit = false;
            if (beamOn && d > 1f && d - s.type.radius < BEAM_RANGE) {
                float ang = (float) Math.atan2(s.y, s.x);
                float tol = half + (float) Math.atan2(s.type.radius * 0.8f, Math.max(d, 1f));
                if (Math.abs(wrap(ang - beamAngle)) <= tol) {
                    s.lit = true;
                    s.hp -= dps * s.type.beamFactor * dt;
                    s.hurt = 0.1f;
                }
            }

            ShadowType ty = s.type;
            if (ty.isBoss()) {
                updateBoss(s, d, dt);
                continue;
            }
            if (d <= LANTERN_R + ty.radius * 0.5f) {
                hitLantern(ty.damage);
                s.hp = 0f;
                s.hurt = -1f; // fenere çarpanlar kıvılcım bırakmaz
                continue;
            }
            float speed = ty.speed * (s.lit ? LIT_SLOW : 1f);
            float dirx = -s.x / d, diry = -s.y / d;
            if (ty == ShadowType.RUNNER) {
                float w = (float) Math.sin(s.age * 5f + s.phase) * 0.45f;
                float cw = (float) Math.cos(w), sw = (float) Math.sin(w);
                float nx = dirx * cw - diry * sw;
                float ny = dirx * sw + diry * cw;
                dirx = nx;
                diry = ny;
            }
            s.x += dirx * speed * dt;
            s.y += diry * speed * dt;
        }
    }

    private void updateBoss(Shadow s, float d, float dt) {
        ShadowType ty = s.type;
        if (d > ty.holdRadius) {
            float speed = ty.speed * (s.lit ? LIT_SLOW : 1f);
            s.x += -s.x / d * speed * dt;
            s.y += -s.y / d * speed * dt;
        } else {
            hitLanternDot(ty.drain * dt);
        }
        s.summonT -= dt;
        if (s.summonT <= 0f) {
            boolean phase2 = s.hp < s.maxHp * 0.5f;
            if (ty == ShadowType.CAPTAIN) {
                s.summonT = 7f;
                spawnAround(ShadowType.RUNNER, s.x, s.y, ty.radius);
                spawnAround(ShadowType.RUNNER, s.x, s.y, ty.radius);
            } else {
                s.summonT = phase2 ? 5f : 7f;
                spawnAround(ShadowType.CRAWLER, s.x, s.y, ty.radius);
                spawnAround(ShadowType.CRAWLER, s.x, s.y, ty.radius);
                if (phase2) spawnAround(ShadowType.RUNNER, s.x, s.y, ty.radius);
            }
        }
    }

    private void hitLantern(float dmg) {
        oil -= dmg;
        if (listener != null) listener.onLanternHit(dmg);
    }

    /** Boss'un sürekli emmesi: olay bildirmeden yağı azaltır. */
    private void hitLanternDot(float dmg) {
        oil -= dmg;
    }

    private void cleanup() {
        for (int i = shadows.size() - 1; i >= 0; i--) {
            Shadow s = shadows.get(i);
            if (s.hp > 0f) continue;
            shadows.remove(i);
            if (s.hurt < 0f) continue; // fenere çarptı
            kills++;
            sparks += s.type.sparks;
            if (listener != null) listener.onKill(s);
            if (s.type == ShadowType.SPLITTER) {
                spawnAround(ShadowType.SPLITLING, s.x, s.y, 22f);
                spawnAround(ShadowType.SPLITLING, s.x, s.y, 22f);
            }
            if (s == boss) {
                boss = null;
                bossDefeated = true;
            }
        }
        if (!pending.isEmpty()) {
            shadows.addAll(pending);
            pending.clear();
        }
    }

    private void checkEnd() {
        if (oil <= 0f) {
            oil = 0f;
            state = State.LOST;
            beamOn = false;
            return;
        }
        if (level.endless) return;
        boolean won;
        if (level.boss != null) won = bossDefeated;
        else won = time >= level.duration;
        if (won) {
            state = State.WON;
            beamOn = false;
            shadows.clear();
            if (listener != null) listener.onDawn();
        }
    }

    // ------------------------------------------------------------- yardımcı

    /** Gece ilerlemesi 0..1 (boss gecelerinde boss canı üzerinden). */
    public float progress() {
        if (level.endless) return 0f;
        if (level.boss != null) {
            if (bossDefeated) return 1f;
            if (boss == null) return Math.min(0.15f, 0.15f * time / Math.max(1f, level.bossAt));
            return 0.15f + 0.85f * (1f - boss.hp / boss.maxHp);
        }
        return Math.min(1f, time / level.duration);
    }

    public static float wrap(float a) {
        double twoPi = Math.PI * 2;
        double r = a % twoPi;
        if (r > Math.PI) r -= twoPi;
        else if (r < -Math.PI) r += twoPi;
        return (float) r;
    }
}
