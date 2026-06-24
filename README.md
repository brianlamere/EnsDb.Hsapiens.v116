# EnsDb.Hsapiens.v116

An `EnsDb` annotation package for *Homo sapiens*, built from **Ensembl
release 116** (GRCh38, June 2026).

## Why this exists

Bioconductor publishes a series of `EnsDb.Hsapiens.vNN` packages
(`EnsDb.Hsapiens.v75`, `v79`, `v86`) via the `ensembldb`/AnnotationHub
ecosystem. That series has not been updated since `v86` (Ensembl release
86, 2016) -- eight years and many Ensembl releases behind current human
gene annotation. This package fills the same role, following the same
naming convention, for release 116.

**This is an independent, unofficial package.** It is not produced,
reviewed, or endorsed by the Bioconductor project or by the maintainers of
the original `EnsDb.Hsapiens.vNN` series.

## What it provides

A single function, `EnsDb.Hsapiens.v116()`, returning an `EnsDb` object
(from the [`ensembldb`](https://bioconductor.org/packages/ensembldb/)
package) -- usable anywhere an `EnsDb` is expected, exactly like
`EnsDb.Hsapiens.v86`:

```r
library(EnsDb.Hsapiens.v116)
edb <- EnsDb.Hsapiens.v116()

library(ensembldb)
genes(edb)
```

All actual query functionality (`genes()`, `transcripts()`,
`exonsBy()`, `GetGRangesFromEnsDb()`, etc.) is provided by `ensembldb`
itself. This package's only job is to provide a correctly-versioned,
correctly-built `EnsDb` object -- it contains no query logic of its own.

## Installation

```r
remotes::install_github("brianlamere/EnsDb.Hsapiens.v116")
```

That's it -- one step, exactly like installing any other annotation
package. No manual build step, no post-install script to remember to run.
The database is fully present and ready to use as soon as install
completes, the same way `EnsDb.Hsapiens.v86` works today.

## How this works

The underlying SQLite database is built from the official Ensembl release
116 GTF for *Homo sapiens* / GRCh38, via
[`inst/scripts/build_ensdb.R`](inst/scripts/build_ensdb.R). That script:

1. Downloads the GTF directly from Ensembl's FTP site (pinned URL --
   see the script).
2. Verifies the download against Ensembl's own published `CHECKSUMS` file
   for that release.
3. Builds the EnsDb SQLite database via `ensembldb::ensDbFromGtf()`.
4. Gzips the result and splits it into chunks under 100MB
   (`EnsDb.Hsapiens.v116.sqlite.gz.part.01`, `.part.02`, ...), since GitHub
   blocks any single committed file over 100MB and this database exceeds
   that on its own. A SHA256 of the uncompressed database is recorded
   alongside the parts as `EnsDb.Hsapiens.v116.sqlite.sha256`.

The chunks committed to this repo are **not a second source of truth** --
they're a storage encoding of the one build that script produces. Anyone
can verify this by re-running the build script against the same pinned
Ensembl source and comparing checksums.

**Reassembly happens automatically during `R CMD INSTALL`**, via the
[`configure`](configure) script -- the standard R mechanism for running
shell code as part of installation (see the R Extensions manual,
"Configure and cleanup"). `remotes::install_github()`,
`devtools::install_local()`, and plain `R CMD INSTALL` all run this
automatically; there is no separate manual step. By the time install
finishes, `inst/extdata/EnsDb.Hsapiens.v116.sqlite` exists in the
installed package directory, fully reassembled and checksum-verified --
behaviorally identical to a package that shipped the file directly. No
network access happens during `configure`; everything needed is already
present from the clone/download `install_github()` already performed.

> **Windows note:** `configure` only runs automatically on Unix-alikes. A
> `configure.win` counterpart would be needed for automatic install on
> Windows; this hasn't been added since the primary deployment target is
> Linux. Manual reassembly (`cat` the parts, `gunzip`, place the result
> in `inst/extdata/`) works anywhere as a fallback.

## Rebuilding from scratch

If you want to verify the committed database independently, or pull a
later Ensembl release under a renamed package, just re-run the build
script and compare the resulting SHA256 to the one committed in
`inst/extdata/EnsDb.Hsapiens.v116.sqlite.sha256`:

```r
source("inst/scripts/build_ensdb.R")
```

This downloads fresh from Ensembl, rebuilds, and re-chunks. If you're
rebuilding to publish an updated version of this package (e.g. a future
Ensembl release), commit the new parts and `.sha256` together as a single
change -- never let committed chunks drift out of sync with the checksum
that's supposed to describe them.

## On reproducibility

The build script is the actual specification of this package's content:
a pinned Ensembl release, a checksum-verified download, and a documented
build command (`ensembldb::ensDbFromGtf()`). The committed chunks exist
purely to make installation convenient (one `install_github()` call, no
manual steps) -- they don't change what the package *is*. If `ensembldb`,
R, or GitHub's storage limits all changed in five years, the same
documented inputs (Ensembl release 116, this GTF, this checksum) should
still let anyone reconstruct an equivalent database. Tooling can change
around this; the inputs don't.

## Versioning

- **Package name** (`EnsDb.Hsapiens.v116`) encodes the Ensembl release it
  tracks, following the existing Bioconductor convention -- the same way
  `EnsDb.Hsapiens.v86` encodes Ensembl release 86.
- **Package `Version:`** field (in `DESCRIPTION`) follows ordinary semver
  for the packaging/build code itself, independent of the Ensembl release
  number.

## Known limitations

- `entrezid` is not populated. Standard Ensembl release GTF files do not
  carry NCBI Entrez Gene cross-references (that's an NCBI-sourced mapping,
  not part of Ensembl's own GTF export) -- this is expected, not a bug in
  the build. If you need Ensembl-to-Entrez mapping, use
  `org.Hs.eg.db` (`AnnotationDbi::select(org.Hs.eg.db, keys = ensembl_ids,
  columns = "ENTREZID", keytype = "ENSEMBL")`) as a separate lookup step.

## Requirements

- R >= 4.1.0
- `ensembldb` (>= 2.0.0), from Bioconductor:
  ```r
  if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
  BiocManager::install("ensembldb")
  ```
- Only required to rebuild from source (`build_ensdb.R`), not to install
  the package itself.

## License

Artistic-2.0, matching the license used by Bioconductor's own
`EnsDb.Hsapiens.vNN` packages and `ensembldb` itself.
