package com.tigirer.sonfener.core;

import com.tigirer.sonfener.core.LevelDef.SpawnRule;

/** Beş gecelik hikâye ve sonsuz mod. */
public final class Levels {
    public static final int COUNT = 5;

    private Levels() {
    }

    public static LevelDef get(int index) {
        switch (index) {
            case 0:
                return new LevelDef("1. Gece · İlk Işık", 50f, null, 0f, false,
                        new SpawnRule(ShadowType.CRAWLER, 0f, 50f, 2.8f, 1.8f, 1));
            case 1:
                return new LevelDef("2. Gece · Fısıltılar", 60f, null, 0f, false,
                        new SpawnRule(ShadowType.CRAWLER, 0f, 60f, 2.3f, 1.5f, 1),
                        new SpawnRule(ShadowType.RUNNER, 8f, 60f, 4.5f, 2.6f, 1));
            case 2:
                return new LevelDef("3. Gece · Sis Perdesi", 65f, ShadowType.CAPTAIN, 35f, false,
                        new SpawnRule(ShadowType.CRAWLER, 0f, 65f, 2.4f, 1.7f, 1),
                        new SpawnRule(ShadowType.RUNNER, 5f, 65f, 4.8f, 3.0f, 1),
                        new SpawnRule(ShadowType.ARMORED, 15f, 65f, 9.0f, 6.5f, 1));
            case 3:
                return new LevelDef("4. Gece · Bölünenler", 70f, null, 0f, false,
                        new SpawnRule(ShadowType.CRAWLER, 0f, 70f, 2.0f, 1.3f, 1),
                        new SpawnRule(ShadowType.RUNNER, 4f, 70f, 3.8f, 2.3f, 1),
                        new SpawnRule(ShadowType.ARMORED, 12f, 70f, 7.5f, 5.0f, 1),
                        new SpawnRule(ShadowType.SPLITTER, 6f, 70f, 5.0f, 3.2f, 1));
            default:
                return new LevelDef("5. Gece · Sis Ana", 75f, ShadowType.MOTHER, 22f, false,
                        new SpawnRule(ShadowType.CRAWLER, 0f, 75f, 2.1f, 1.5f, 1),
                        new SpawnRule(ShadowType.RUNNER, 4f, 75f, 4.0f, 2.8f, 1),
                        new SpawnRule(ShadowType.ARMORED, 10f, 75f, 8.0f, 5.5f, 1),
                        new SpawnRule(ShadowType.SPLITTER, 6f, 75f, 5.5f, 3.8f, 1));
        }
    }

    public static LevelDef endless() {
        return new LevelDef("Sonsuz Gece", Float.MAX_VALUE, null, 0f, true);
    }
}
