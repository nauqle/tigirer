class_name UiFormat
extends RefCounted
## Sayı ve süre biçimleme, DİLE DUYARLI: Türkçede binlik ayracı nokta, ondalık virgül (12.480 · 1,5); İngilizcede binlik virgül,
## ondalık nokta (12,480 · 1.5). Metin içine elle `%d` ile gömülen sayılar da bu sınıftan geçer ki iki dil de doğal okunsun.
##
## Uygular: design/design-language.md, "Yazım sesi ve biçim".
##
## [codeblock]
## UiFormat.number(12480)        # "12.480" (tr) / "12,480" (en)
## UiFormat.compact(1250000)     # "1,25 Mn" (tr) / "1.25M" (en)
## UiFormat.decimal(1.6, 2)      # "1,60" (tr) / "1.60" (en)
## [/codeblock]


## Etkin dilde Türkçe sayı yazımı mı kullanılıyor?
static func uses_decimal_comma() -> bool:
	return TranslationServer.get_locale().begins_with("tr")


## Tam sayı, binlik ayraçlı.
static func number(value: int) -> String:
	var digits: String = str(absi(value))
	var separator: String = "." if uses_decimal_comma() else ","
	var grouped: String = ""
	var count: int = 0
	for i: int in range(digits.length() - 1, -1, -1):
		grouped = digits[i] + grouped
		count += 1
		if count % 3 == 0 and i > 0:
			grouped = separator + grouped
	return ("-" if value < 0 else "") + grouped


## Ondalıklı sayı (`digits` basamak), dilin ondalık ayracıyla.
static func decimal(value: float, digits: int = 1) -> String:
	var text: String = ("%." + str(maxi(digits, 0)) + "f") % value
	return text.replace(".", ",") if uses_decimal_comma() else text


## Büyük sayıları kısaltır: 1 milyondan itibaren "1,25 Mn" / "1.25M"; altı tam sayıdır.
static func compact(value: int) -> String:
	if absi(value) < 1000000:
		return number(value)
	var unit: String = " Mn" if uses_decimal_comma() else "M"
	var scaled: float = float(value) / 1000000.0
	return decimal(scaled, 2) + unit


## Saniyeyi "d:ss" ya da "s:dd:ss" metnine çevirir.
static func clock(seconds: float) -> String:
	var total: int = maxi(int(seconds), 0)
	if total >= 3600:
		return "%d:%02d:%02d" % [total / 3600, (total % 3600) / 60, total % 60]
	return "%d:%02d" % [total / 60, total % 60]


## Yüzde (0..1 -> "%45" Türkçe, "45%" İngilizce).
static func percent(ratio: float) -> String:
	var value: int = int(round(ratio * 100.0))
	return "%%%d" % value if uses_decimal_comma() else "%d%%" % value


## İşaretli yüzde: "+12%" / "-8%" (Türkçede "+%12" / "-%8"); sıfır işaretsizdir.
static func signed_percent(ratio: float) -> String:
	var value: int = int(round(ratio * 100.0))
	var sign_text: String = "+" if value > 0 else ("-" if value < 0 else "")
	return sign_text + percent(absf(ratio))
