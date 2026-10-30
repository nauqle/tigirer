package com.tigirer.sonfener.core;

/** Atölyede satın alınan fener geliştirmeleri. */
public final class Upgrades {
    public static final int POWER = 0, WIDTH = 1, TANK = 2, COOL = 3, OIL = 4, FLASH = 5;
    public static final int COUNT = 6;
    public static final int MAX_LEVEL = 5;

    public static final String[] NAMES = {
            "Işık Gücü", "Işın Genişliği", "Enerji Deposu", "Soğutma", "Fener Yağı", "Parlama"
    };
    public static final String[] DESCS = {
            "Işının saniyedeki hasarı artar",
            "Işın daha geniş bir alanı aydınlatır",
            "Işın daha uzun süre yanar",
            "Işık kapalıyken enerji daha hızlı dolar",
            "Fener daha fazla darbe taşır",
            "Parlama daha sert vurur, daha sık kullanılır"
    };
    private static final int[] COSTS = {10, 20, 34, 52, 76};

    public final int[] level = new int[COUNT];

    public float beamDps() {
        return 40f + 9f * level[POWER];
    }

    public float beamHalfAngle() {
        return (float) Math.toRadians(13 + 3 * level[WIDTH]);
    }

    public float maxEnergy() {
        return 100f + 25f * level[TANK];
    }

    public float regen() {
        return 26f + 5f * level[COOL];
    }

    public float maxOil() {
        return 100f + 20f * level[OIL];
    }

    public float flashDamage() {
        return 90f + 35f * level[FLASH];
    }

    public float flashCooldown() {
        return 14f - 1.5f * level[FLASH];
    }

    /** Bir sonraki seviyenin bedeli; azami seviyedeyse -1. */
    public int cost(int which) {
        return level[which] >= MAX_LEVEL ? -1 : COSTS[level[which]];
    }

    public boolean canBuy(int which, int sparks) {
        int c = cost(which);
        return c >= 0 && sparks >= c;
    }

    /** Satın alır ve harcanan kıvılcımı döndürür; alınamazsa 0. */
    public int buy(int which, int sparks) {
        if (!canBuy(which, sparks)) return 0;
        int c = cost(which);
        level[which]++;
        return c;
    }

    public Upgrades copy() {
        Upgrades u = new Upgrades();
        System.arraycopy(level, 0, u.level, 0, COUNT);
        return u;
    }
}
