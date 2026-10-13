---
name: typst
description: Use when editing or creating Typst (.typ) documents, templates, or PDF output in this project; also for Typst syntax, styling, layout, tables, and accessibility questions.
---

# Typst in this project

The résumé entry point is `static/latex/resume.typ`; it imports `static/latex/template.typ`, which defines `project`, `section`, `subSection`, and `contact`. The template renders the header and two-column body with `grid` and resolves icon images by relative `.svg` paths. Keep content changes in `resume.typ` and shared rendering changes in `template.typ`.

## Workflow

1. Read the entry point and imported template before editing. Identify whether the request affects content, a reusable component, or page layout; preserve the existing `#show: project.with(...)` interface unless changing that interface is the task.
2. For unfamiliar Typst behavior, consult the specific [official reference](https://typst.app/docs/reference/) entry or [guide](https://typst.app/docs/guides/) below. Check the installed compiler version with `typst --version` before relying on recently introduced features.
3. Make the smallest source change. Keep Typst's modes straight: markup is the default; `#` enters code; `[...]` creates markup content inside code; `$...$` enters math. Inside code blocks and function arguments, use code syntax without another `#` until re-entering markup.
4. Compile the entry point, not just the imported template: `typst compile static/latex/resume.typ "${TMPDIR:-/tmp}/typst-resume-check.pdf"`. Confirm compilation succeeds and inspect the rendered PDF when changes affect spacing, wrapping, icons, or pagination. Report if visual inspection is unavailable. Put disposable output outside the repo.

## Decisions that matter

- Use `#set` for configurable element properties and `#show` for selected transformations or whole-document templates. Scope rules in blocks when they should not affect later content. Place `#set page(...)` near the start: changing page setup can insert a page break. See [Styling](https://typst.app/docs/reference/styling/) and [Page Setup](https://typst.app/docs/guides/page-setup/).
- Use `context` for location- or style-dependent values (such as page counters and queries); keep calculations that depend on those values inside the context expression. See [Context](https://typst.app/docs/reference/context/).
- Use `grid` for visual layout, `table` for actual tabular data. For tables, use `table.header` for header cells, `table.cell` for spans, and `figure(table(...), caption: [...]) <label>` when a caption and reference are needed. See the [Table Guide](https://typst.app/docs/guides/tables/) and [table reference](https://typst.app/docs/reference/model/table/).
- Preserve document semantics alongside appearance: use headings and lists for structure, descriptive links, `image(alt: ...)` for meaningful images, and a logical source reading order across grids. Check the [Accessibility Guide](https://typst.app/docs/guides/accessibility/) before changing exported-document structure; PDF/UA validation is a separate export choice, not implied by a successful ordinary PDF build.

## Reference routes

- New to Typst or translating LaTeX conventions: [LaTeX User Guide](https://typst.app/docs/guides/for-latex-users/) and [Syntax](https://typst.app/docs/reference/syntax/).
- Template functions, imports, and argument spreading: [Scripting](https://typst.app/docs/reference/scripting/) and [Arguments](https://typst.app/docs/reference/foundations/arguments/).
- Columns, margins, headers, and page numbering: [Page Setup Guide](https://typst.app/docs/guides/page-setup/) and [page reference](https://typst.app/docs/reference/layout/page/).
- Output-format-specific options: [PDF reference](https://typst.app/docs/reference/pdf/) and [HTML reference](https://typst.app/docs/reference/html/); verify supported features against the installed compiler.
