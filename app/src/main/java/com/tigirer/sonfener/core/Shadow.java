package com.tigirer.sonfener.core;

/** Sahnedeki tek bir gölge. Koordinatlar fenere göre (fener = 0,0). */
public final class Shadow {
    public final ShadowType type;
    public float x, y;
    public float hp;
    public final float maxHp;
    public float age;
    public final float phase;
    public boolean lit;
    /** Hasar alınca kısa süre parlayan efekt sayacı. */
    public float hurt;
    /** Boss çağrı sayacı. */
    public float summonT;

    public Shadow(ShadowType type, float x, float y, float hpScale, float phase) {
        this.type = type;
        this.x = x;
        this.y = y;
        this.maxHp = type.maxHp * hpScale;
        this.hp = this.maxHp;
        this.phase = phase;
        this.summonT = 3f;
    }

    public float dist() {
        return (float) Math.sqrt(x * x + y * y);
    }
}
