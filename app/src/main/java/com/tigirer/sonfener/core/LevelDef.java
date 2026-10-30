package com.tigirer.sonfener.core;

/** Bir gecenin tanımı: süre, gölge doğurma kuralları ve varsa boss. */
public final class LevelDef {

    /** [start, end] aralığında, aralığı i0'dan i1'e doğrusal azalan sıklıkta gölge doğurur. */
    public static final class SpawnRule {
        public final ShadowType type;
        public final float start, end, i0, i1;
        public final int group;

        public SpawnRule(ShadowType type, float start, float end, float i0, float i1, int group) {
            this.type = type;
            this.start = start;
            this.end = end;
            this.i0 = i0;
            this.i1 = i1;
            this.group = group;
        }
    }

    public final String name;
    public final float duration;
    public final SpawnRule[] rules;
    public final ShadowType boss;
    public final float bossAt;
    public final boolean endless;

    public LevelDef(String name, float duration, ShadowType boss, float bossAt, boolean endless,
                    SpawnRule... rules) {
        this.name = name;
        this.duration = duration;
        this.boss = boss;
        this.bossAt = bossAt;
        this.endless = endless;
        this.rules = rules;
    }
}
