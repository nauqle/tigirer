class_name SegmentMath
extends RefCounted
## Parmak izi (kaydırma) için geometri: bir doğru parçası bir dikdörtgene değiyor mu? Saf ve oyundan bağımsızdır.
##
## [codeblock]
## var hit: bool = SegmentMath.segment_hits_rect(last_point, point, Rect2(100, 100, 50, 80))
## [/codeblock]


## `a`'dan `b`'ye çizilen doğru parçası `rect` ile kesişiyor ya da içinde mi? (Liang-Barsky kırpması.)
## Sıfır uzunluklu parça (a == b) bir nokta gibi sınanır. Kenara değmek isabettir.
static func segment_hits_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	var direction: Vector2 = b - a
	var p: Array[float] = [-direction.x, direction.x, -direction.y, direction.y]
	var q: Array[float] = [a.x - rect.position.x, rect.end.x - a.x, a.y - rect.position.y, rect.end.y - a.y]
	var t_enter: float = 0.0
	var t_exit: float = 1.0
	for i: int in 4:
		if is_zero_approx(p[i]):
			if q[i] < 0.0:
				return false
			continue
		var t: float = q[i] / p[i]
		if p[i] < 0.0:
			if t > t_exit:
				return false
			t_enter = maxf(t_enter, t)
		else:
			if t < t_enter:
				return false
			t_exit = minf(t_exit, t)
	return true
