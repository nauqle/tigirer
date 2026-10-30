class_name ColorMath
extends RefCounted
## Renk tonu (HSV hue) için küçük, oyundan bağımsız matematik yardımcıları.
##
## Ton [0, 1) aralığında DAİRESELDİR: 0.95 ile 0.05 birbirine 0.1 uzaklıktadır, 0.9 değil.
## Sıradan ortalama (a + b) / 2 bu dikişte yanlış renk verir: kırmızıya yakın iki ton camgöbeğine
## ortalanır. Burada hepsi daire üzerindeki KISA yay boyunca hesaplanır.
## Bu dosya oyun koduna bağımlı değildir (src/core kuralı: motor oyuna bağlanmaz).


## Tonu [0, 1) aralığına sarar.
## [codeblock]
## ColorMath.wrap_hue(1.25)  # 0.25
## ColorMath.wrap_hue(-0.1)  # 0.9
## [/codeblock]
static func wrap_hue(hue: float) -> float:
	return fposmod(hue, 1.0)


## İki ton arasındaki en kısa daire mesafesi, [0, 0.5] aralığında.
## [codeblock]
## ColorMath.hue_distance(0.95, 0.05)  # 0.1
## [/codeblock]
static func hue_distance(a: float, b: float) -> float:
	var gap: float = absf(wrap_hue(a) - wrap_hue(b))
	return minf(gap, 1.0 - gap)


## İki tonun dairesel ortalaması: daire üzerindeki kısa yayın orta noktası. Sıradan bağımsızdır;
## tam karşıt tonlarda (fark 0.5) da her iki sırada aynı sonucu verir.
## [codeblock]
## ColorMath.mix_hues(0.95, 0.05)  # 0.0 (kırmızı), 0.5 değil
## ColorMath.mix_hues(0.1, 0.3)    # 0.2
## [/codeblock]
static func mix_hues(a: float, b: float) -> float:
	var wrapped_a: float = wrap_hue(a)
	var wrapped_b: float = wrap_hue(b)
	var low: float = minf(wrapped_a, wrapped_b)
	var high: float = maxf(wrapped_a, wrapped_b)
	var gap: float = high - low
	if gap <= 0.5:
		return wrap_hue(low + gap * 0.5)
	return wrap_hue(high + (1.0 - gap) * 0.5)


## Tonu `to` hedefine doğru, kısa yay boyunca, `weight` oranında (0..1) kaydırır.
## [codeblock]
## ColorMath.lerp_hue(0.2, 0.6, 0.0)  # 0.2
## ColorMath.lerp_hue(0.9, 0.1, 0.5)  # 0.0 (dikişi geçerek yarı yol)
## [/codeblock]
static func lerp_hue(from: float, to: float, weight: float) -> float:
	var delta: float = wrapf(to - from, -0.5, 0.5)
	return wrap_hue(from + delta * weight)
