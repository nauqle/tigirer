package com.tigirer.sonfener.core;

/** Hikâye metinleri. Her dizi, dokunarak ilerlenen sayfalardır. */
public final class Story {
    private Story() {
    }

    public static final String[] PROLOGUE = {
            "Kandil Burnu'nun feneri üç yüz yıldır hiç sönmedi.\n\nGemiler onu uzaktan görür, denizciler ona bakarak eve yolunu bulurdu.",
            "Sonra bir sabah Usta Hızır ortadan kayboldu.\n\nGeriye yalnızca fenerin anahtarı ve yarım kalmış bir defter bıraktı.",
            "Defterin son sayfasında şu yazıyordu:\n\n\u201CSis uyanırsa ışığı söndürme. Gölgeler karanlıktan değil, unutulmaktan gelir.\u201D\n\nBu gece sis kasabaya iniyor. Fener artık senin."
    };

    public static final String[][] NIGHT_INTRO = {
            {"Güneş battı. Denizden ince bir sis yükseliyor.\n\nMerdiveni çıkıp feneri yaktın. Gölgeler kıyıya doğru sürünüyor.\n\nEkrana dokun ve parmağını kaydır: ışık parmağının gösterdiği yöne döner."},
            {"Rüzgârda isimler fısıldanıyor: Selim\u2026 Nesrin\u2026 Cemal\u2026\n\nBu gece gölgeler daha hızlı. Işın enerji harcar; tükenirse ışık soğur ve bir süre yanmaz. Ritmini bul."},
            {"Sis kalınlaştı. Bazı gölgeler zırh gibi bir sisle sarılı; ışık onlara zor işliyor.\n\nParlama düğmesi bu zırhı deler.\n\nUfukta eski bir geminin silueti beliriyor: Kaptan Gölge."},
            {"Bu gece gölgeler çoğalıyor. Bazıları ölünce iki küçük parçaya ayrılıyor.\n\nKasabadan kimse kapısını açmıyor; yine de pencerelerde mum ışıkları görüyorsun."},
            {"Son gece. Deniz çekiliyor, gökyüzü susuyor.\n\nSis'in kalbi yaklaşıyor: Sis Ana. Yüzyıllardır unutulan herkesin gölgesi onda birikmiş.\n\nOnu yenmek yetmez; hatırlamak gerek."}
    };

    public static final String[][] NIGHT_OUTRO = {
            {"Sürüngenler ışıkta dağıldı ve geriye altın kıvılcımlar kaldı. Her biri küçük bir anı gibi parlıyor.\n\nDefterde yeni bir satır belirmiş:\n\u201CKıvılcımlar unutulmuş anılardır. Topla; fener daha parlak yansın.\u201D"},
            {"Fısıltılar kesildi. Defterin kenarında bir gemi listesi buldun; hepsi bu körfezde kaybolmuş.\n\nAdlar silik ama hâlâ okunuyor."},
            {"Kaptan Gölge dağılırken son sözünü fısıldadı:\n\u201CBizi unuttular\u2026 Ama sen hâlâ buradasın.\u201D\n\nKaptanın pusulası kıvılcımlara karıştı. Onu fenerin yanına astın."},
            {"Parçalar da dağıldı. Fenerin kapısına bir sepet ekmek ve bir not bırakılmış:\n\u201CBizi hatırlıyorsun, biz de seni.\u201D\n\nSis zayıflıyor. Ama kaynağı hâlâ denizin ortasında."},
            {}
    };

    public static final String[] EPILOGUE = {
            "Sis Ana dağılırken binlerce kıvılcıma ayrıldı. Her biri bir ad, bir yüz, bir ses\u2026\n\nHepsini fenerin camına bıraktın.",
            "Fener, kasabanın tarihinde ilk kez gündüz de yandı.\n\nUfukta gemiler belirdi; yıllar önce kaybolanlar, dümenlerinde fener ışığıyla eve dönüyordu.",
            "Rıhtımda, gemilerden birinden inen yaşlı bir silüet el salladı: Usta Hızır.\n\nDefterin son sayfasına kendi satırını yazdın:\n\u201CIşık gölgeyi yenmez; onu eve götürür.\u201D",
            "SON FENER\n\nTamamladın. Fener artık senin.\n\nİstersen \u201CSonsuz Gece\u201D modunda ne kadar dayanabileceğini dene."
    };

    public static final String[] HOW_TO = {
            "Ekrana dokun ve parmağını kaydır: fener ışını parmağına doğru döner.",
            "Işın enerji harcar. Enerji biterse ışık soğur ve yeniden dolana kadar yanmaz.",
            "Işıktaki gölgeler yavaşlar ve erir. Fenere ulaşan gölge yağı azaltır; yağ biterse fener söner.",
            "Sağ alttaki PARLAMA düğmesi çevredeki tüm gölgelere vurur, geri iter ve zırhı deler.",
            "Her gece şafağa kadar dayan. Boss gecelerinde boss'u yen.",
            "Kıvılcımlar unutulmuş anılardır. Atölyede fenerini geliştirmek için harca."
    };
}
