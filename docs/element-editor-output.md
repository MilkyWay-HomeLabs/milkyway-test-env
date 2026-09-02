# element-editor output

`element-editor-rest-test` writes generated card art to
`resources/test/element-editor/<card-code>/{card.png,source.<ext>}` on the host — bind-mounted
into the container at `/app/output` (`OUTPUT_DIR` in
`env/element-editor/element-editor-rest.env`). `GET /element/editor/api/cards/status` derives
"saved" straight from what's on disk: a card is done iff `<card-code>/card.png` exists — there
is no separate tracked store to fall out of sync with the files.

`resources/test/` sits outside every git repo in this lab (root `.gitignore`'s `/resources/`),
same as `resources/test/element/`'s existing `cpu-avatars`/`cpu-players`.

## Backup coverage: none, on purpose

`backup-test` (see `docs/BACKUP_GUIDE.md`) dumps MariaDB, PostgreSQL and MongoDB only — nothing
in this environment backs up `resources/test/` at the filesystem level, for any app, and this
directory is no exception. Worth stating plainly rather than assuming, per this lab's standing
rule to verify what actually happened rather than trust that something must be covered.

In element-editor's case the gap is low-severity: every file under
`resources/test/element-editor/` is regenerable from the editor itself (the source image came
from a URL or a local upload; the composited card is a pure function of that image plus the
card's catalogue data) — losing the directory loses convenience, not anything that cannot be
rebuilt.
