# Üçüncü taraf bileşenler

| Bileşen | Sürüm | Lisans | Kaynak |
|---|---|---|---|
| Claude Code Game Studios (çalışma çerçevesi) | 1.2.0 (commit `05ad7c8`) | MIT, © 2026 Donchitos | https://github.com/Donchitos/Claude-Code-Game-Studios |
| Bricolage Grotesque (başlık yazı tipi) | değişken yazı tipi, `wght` ekseni | SIL OFL 1.1, © 2022 The Bricolage Grotesque Project Authors | https://github.com/ateliertriay/bricolage |
| Nunito Sans (gövde yazı tipi) | değişken yazı tipi, `wght` ekseni | SIL OFL 1.1, © 2016 The Nunito Sans Project Authors | https://github.com/Fonthausen/NunitoSans |

**Claude Code Game Studios** şu yollara kopyalanmıştır: `.claude/`, `CLAUDE.md`, `project.yaml`, `UPGRADING.md`,
`design/`, `docs/` (çerçeve belgeleri ve motor referansları), `production/`, `src/CLAUDE.md`, `studio-tests/`,
`.gitattributes`, `.worktreeinclude`. Lisans metni: [`LICENSES/Claude-Code-Game-Studios.MIT.txt`](LICENSES/Claude-Code-Game-Studios.MIT.txt).

Şablonun yalnızca kendi bakımına ait dosyaları bilerek **kopyalanmadı**: `.github/` (CODEOWNERS, FUNDING, issue/PR şablonları),
`SECURITY.md`, `CONTRIBUTING.md`, `CHANGELOG.md`.

Şablon, günde bir kez GitHub'dan yeni sürüm olup olmadığına bakan bir oturum-başı hook'u içerir
(`.claude/hooks/update-check.sh`). Yalnızca sana bildirim satırı gösterir, hiçbir şey indirmez. Kapatmak için `/settings --local updates.check=false` (sadece sen) ya da `project.yaml` içinde `updates.check: false`.

**Yazı tipleri** `assets/fonts/` altında, değiştirilmeden, oyunun paketine gömülür. Lisans metinleri yazı tipi dosyalarının yanındadır:
[`OFL-BricolageGrotesque.txt`](assets/fonts/OFL-BricolageGrotesque.txt) ve [`OFL-NunitoSans.txt`](assets/fonts/OFL-NunitoSans.txt).
SIL OFL 1.1 yazı tiplerinin oyunla birlikte dağıtılmasına izin verir; yazı tipleri tek başına satılamaz. Oyundaki simgeler ve
ses efektleri bu depodaki betiklerle (`tools/art/make_icons.py`, `src/ui/audio/sfx_bank.gd`) üretilmiştir; üçüncü taraf sanat ya da ses içermez.
