class_name Localization
extends RefCounted
## Arayüz dili: çeviri tablosunu seçer (`TranslationServer`). Çeviri sütunları `assets/i18n/*.csv` dosyalarındadır (strings = arayüz,
## content = oyun içeriği: bitki parçaları, olaylar, siparişler ...). Oyun verisi (.tres) çeviri ANAHTARI tutar; gösterirken `tr()`.
## Desteklenmeyen/boş dil İngilizceye düşer; ilk açılışta dil işletim sistemi dilinden seçilir (`GameSettings.default_language`).
##
## Uygular: design/design-language.md, "Yazım sesi ve biçim"; kullanıcı isteği: Türkçe + İngilizce.
##
## [codeblock]
## Localization.apply(settings.language)          # "tr" | "en"
## var name: String = Localization.name_of("en")  # "English"
## [/codeblock]

## Dillerin kendi dillerindeki adları (dil seçicide çevrilmez).
const NAMES: Dictionary = {"tr": "Türkçe", "en": "English"}
const FALLBACK: String = "en"


## Seçilen dili etkinleştirir; geçersiz kod İngilizceye düşer.
static func apply(language: String) -> void:
	TranslationServer.set_locale(language if GameSettings.LANGUAGES.has(language) else FALLBACK)


## Etkin dil kodu ("tr", "en").
static func current() -> String:
	return TranslationServer.get_locale().substr(0, 2)


## Dilin kendi adı; bilinmeyen kod için kodun kendisi.
static func name_of(language: String) -> String:
	return String(NAMES.get(language, language))


## İşletim sisteminin dil kodu (örn. "tr", "en").
static func system_language() -> String:
	return OS.get_locale_language()
