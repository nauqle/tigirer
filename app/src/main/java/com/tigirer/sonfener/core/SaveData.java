package com.tigirer.sonfener.core;

/** Kalıcı oyun durumu. Düz metne çevrilip SharedPreferences'ta saklanır. */
public final class SaveData {
    /** Oynanabilir en ileri gece (0 tabanlı). */
    public int unlocked;
    public int sparks;
    public final Upgrades up = new Upgrades();
    public boolean completed;
    public boolean prologueSeen;
    public boolean sound = true;
    public float endlessBest;

    public String serialize() {
        StringBuilder sb = new StringBuilder("v1");
        sb.append(';').append(unlocked);
        sb.append(';').append(sparks);
        sb.append(';');
        for (int i = 0; i < Upgrades.COUNT; i++) {
            if (i > 0) sb.append(',');
            sb.append(up.level[i]);
        }
        sb.append(';').append(completed ? 1 : 0);
        sb.append(';').append(prologueSeen ? 1 : 0);
        sb.append(';').append(sound ? 1 : 0);
        sb.append(';').append(endlessBest);
        return sb.toString();
    }

    /** Bozuk ya da boş girdide güvenli varsayılanları döndürür. */
    public static SaveData parse(String s) {
        SaveData d = new SaveData();
        if (s == null) return d;
        try {
            String[] p = s.split(";");
            if (p.length < 8 || !p[0].equals("v1")) return d;
            d.unlocked = clamp(Integer.parseInt(p[1]), 0, Levels.COUNT - 1);
            d.sparks = Math.max(0, Integer.parseInt(p[2]));
            String[] lv = p[3].split(",");
            for (int i = 0; i < Upgrades.COUNT && i < lv.length; i++) {
                d.up.level[i] = clamp(Integer.parseInt(lv[i]), 0, Upgrades.MAX_LEVEL);
            }
            d.completed = p[4].equals("1");
            d.prologueSeen = p[5].equals("1");
            d.sound = p[6].equals("1");
            d.endlessBest = Math.max(0f, Float.parseFloat(p[7]));
        } catch (RuntimeException e) {
            return new SaveData();
        }
        return d;
    }

    private static int clamp(int v, int lo, int hi) {
        return Math.max(lo, Math.min(hi, v));
    }
}
