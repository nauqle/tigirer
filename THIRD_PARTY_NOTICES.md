# Üçüncü taraf bileşenler

| Bileşen | Sürüm | Lisans | Kaynak |
|---|---|---|---|
| Claude Code Game Studios (çalışma çerçevesi) | 1.2.0 (commit `05ad7c8`) | MIT, © 2026 Donchitos | https://github.com/Donchitos/Claude-Code-Game-Studios |

**Claude Code Game Studios** şu yollara kopyalanmıştır: `.claude/`, `CLAUDE.md`, `project.yaml`, `UPGRADING.md`,
`design/`, `docs/` (çerçeve belgeleri ve motor referansları), `production/`, `src/CLAUDE.md`, `studio-tests/`,
`.gitattributes`, `.worktreeinclude`. Lisans metni: [`LICENSES/Claude-Code-Game-Studios.MIT.txt`](LICENSES/Claude-Code-Game-Studios.MIT.txt).

Şablonun yalnızca kendi bakımına ait dosyaları bilerek **kopyalanmadı**: `.github/` (CODEOWNERS, FUNDING, issue/PR şablonları),
`SECURITY.md`, `CONTRIBUTING.md`, `CHANGELOG.md`.

Şablon, günde bir kez GitHub'dan yeni sürüm olup olmadığına bakan bir oturum-başı hook'u içerir
(`.claude/hooks/update-check.sh`). Yalnızca sana bildirim satırı gösterir, hiçbir şey indirmez. Kapatmak için `/settings --local updates.check=false` (sadece sen) ya da `project.yaml` içinde `updates.check: false`.
