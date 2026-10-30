class_name CommandResult
extends RefCounted
## Bir oyuncu komutunun sonucu: başarılı mı, oyuncuya gösterilecek mesajın çeviri anahtarı ve biçim argümanları.
## Arayüz komutu tetikler, sonucu alır, mesajı `tr(anahtar) % argümanlar` ile gösterir; durumu kendisi değiştirmez.
##
## Uygular: design/game-brief.md, mimari kural "arayüz durumu doğrudan değiştirmez, komut/olay kullanır".
##
## [codeblock]
## var result: CommandResult = session.buy_irrigation(0, 1)
## if not result.ok:
##     toast(tr(result.message_key) % result.args)
## [/codeblock]

var ok: bool = false
## Çeviri anahtarı (assets/i18n/strings.csv). Boş olabilir (sessiz başarı).
var message_key: String = ""
## `tr(message_key) % args` için biçim argümanları.
var args: Array = []


## Başarılı sonuç.
static func success(key: String = "", format_args: Array = []) -> CommandResult:
	var result: CommandResult = CommandResult.new()
	result.ok = true
	result.message_key = key
	result.args = format_args
	return result


## Başarısız sonuç; `key` nedeni anlatan çeviri anahtarıdır.
static func failure(key: String, format_args: Array = []) -> CommandResult:
	var result: CommandResult = CommandResult.new()
	result.ok = false
	result.message_key = key
	result.args = format_args
	return result
