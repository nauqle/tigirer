package com.tigirer.sonfener.core;

/** Gölge türleri ve temel özellikleri. */
public enum ShadowType {
    //        ad               can    hız   hasar yarıçap kıvılcım ışın-çarpanı tutunma sömürü
    CRAWLER("Sürüngen",        40f,   55f,   8f,   32f,   1,  1.00f,    0f,    0f),
    RUNNER("Koşucu",           22f,  125f,   6f,   25f,   1,  1.00f,    0f,    0f),
    ARMORED("Zırhlı",         180f,   36f,  20f,   46f,   4,  0.45f,    0f,    0f),
    SPLITTER("Bölünen",        70f,   58f,  10f,   37f,   2,  1.00f,    0f,    0f),
    SPLITLING("Parçacık",      18f,   95f,   4f,   18f,   1,  1.00f,    0f,    0f),
    CAPTAIN("Kaptan Gölge",   600f,   30f,   0f,   88f,  40,  1.00f,  170f,  3.5f),
    MOTHER("Sis Ana",        1700f,   22f,   0f,  120f, 100,  0.85f,  190f,  4.5f);

    public final String label;
    public final float maxHp;
    public final float speed;
    /** Fenere çarptığında yağdan düşen miktar. */
    public final float damage;
    public final float radius;
    public final int sparks;
    /** Işık hasarının bu türe uygulanan çarpanı (zırh). Parlama bunu yok sayar. */
    public final float beamFactor;
    /** Boss'lar fenerden bu mesafede durur. 0 ise doğrudan fenere yürür. */
    public final float holdRadius;
    /** Boss durduktan sonra saniyede yağdan çaldığı miktar. */
    public final float drain;

    ShadowType(String label, float maxHp, float speed, float damage, float radius, int sparks,
               float beamFactor, float holdRadius, float drain) {
        this.label = label;
        this.maxHp = maxHp;
        this.speed = speed;
        this.damage = damage;
        this.radius = radius;
        this.sparks = sparks;
        this.beamFactor = beamFactor;
        this.holdRadius = holdRadius;
        this.drain = drain;
    }

    public boolean isBoss() {
        return holdRadius > 0f;
    }
}
