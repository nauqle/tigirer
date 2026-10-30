package com.tigirer.sonfener.core;

/** Dengeyi ölçmek için basit bir oyuncu: en yakın gölgeyi hedefler, kalabalıkta parlama atar. */
final class Bot {
    final World.State result;
    final World world;

    /** reaction: hedef değiştirme aralığı (sn); ne kadar büyükse bot o kadar beceriksiz. */
    Bot(int night, Upgrades up, long seed, float reaction, float aspect, float maxSeconds) {
        LevelDef def = night < 0 ? Levels.endless() : Levels.get(night);
        world = new World(def, up, aspect, seed);
        float dt = 1f / 60f;
        float retarget = 0f;
        Shadow target = null;
        while (world.state == World.State.PLAYING && world.time < maxSeconds) {
            retarget -= dt;
            if (retarget <= 0f || target == null || !world.shadows.contains(target)) {
                retarget = reaction;
                target = pick(world);
            }
            if (target != null) {
                float ang = (float) Math.atan2(target.y, target.x);
                // hızlı gölgeler için biraz önden nişan al
                world.setBeam(true, ang);
                // enerji tasarrufu: hedef menzil dışındaysa ışığı kapat
                if (target.dist() - target.type.radius > World.BEAM_RANGE + 30f
                        || world.overheated) {
                    world.setBeam(false, ang);
                }
            } else {
                world.setBeam(false, world.beamAngle);
            }
            if (shouldFlash(world)) world.flash();
            world.update(dt);
        }
        result = world.state;
    }

    private static Shadow pick(World w) {
        Shadow best = null;
        float bestScore = Float.MAX_VALUE;
        for (Shadow s : w.shadows) {
            float d = s.dist() - s.type.radius;
            // boss ışık menzilindeyse ve yakınsa öncelik ver; yoksa en yakını hedefle
            float score = d / (s.type.speed + 40f) * 100f;
            if (s.type.isBoss()) score *= 1.4f;
            if (score < bestScore) {
                bestScore = score;
                best = s;
            }
        }
        return best;
    }

    private static boolean shouldFlash(World w) {
        if (w.flashCd > 0f) return false;
        int near = 0;
        boolean armored = false;
        for (Shadow s : w.shadows) {
            float d = s.dist() - s.type.radius;
            if (d < 300f) near++;
            if (s.type == ShadowType.ARMORED && d < 260f) armored = true;
            if (s.type.isBoss() && d < 440f) near += 3;
        }
        return near >= 4 || armored;
    }
}
