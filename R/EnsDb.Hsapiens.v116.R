#' EnsDb.Hsapiens.v116: Ensembl 116 Annotation Database for Homo sapiens
#'
#' Returns an \code{EnsDb} object (see the \pkg{ensembldb} package) backed by
#' a SQLite database built directly from the Ensembl release 116 GTF for
#' \emph{Homo sapiens} / GRCh38. See \code{system.file("scripts",
#' "build_ensdb.R", package = "EnsDb.Hsapiens.v116")} for the full,
#' reproducible build procedure used to generate the underlying database.
#'
#' This package is an independently maintained continuation of the naming
#' convention used by Bioconductor's \code{EnsDb.Hsapiens.vNN} package
#' series (\code{v75}, \code{v79}, \code{v86}), which has not been updated
#' past Ensembl release 86. This package is not produced or endorsed by the
#' Bioconductor project.
#'
#' @return An object of class \code{EnsDb}.
#' @examples
#' \dontrun{
#' edb <- EnsDb.Hsapiens.v116()
#' ensembldb::genes(edb)
#' }
#' @export
EnsDb.Hsapiens.v116 <- function() {
  db_path <- system.file(
    "extdata", "EnsDb.Hsapiens.v116.sqlite",
    package = "EnsDb.Hsapiens.v116"
  )

  if (db_path == "" || !file.exists(db_path)) {
    stop(
      "EnsDb.Hsapiens.v116.sqlite was not found in this package's extdata/ ",
      "directory. The database is normally reassembled automatically by ",
      "the package's 'configure' script during installation -- seeing this ",
      "error means that step did not run or did not complete successfully ",
      "(e.g. installing on Windows without a configure.win counterpart, or ",
      "a build from a source checkout where the chunked parts were never ",
      "committed). Try reinstalling and check the install log for messages ",
      "from 'configure:'. See the package README for details."
    )
  }

  ensembldb::EnsDb(db_path)
}

#' @noRd
.onAttach <- function(libname, pkgname) {
  db_path <- system.file(
    "extdata", "EnsDb.Hsapiens.v116.sqlite",
    package = "EnsDb.Hsapiens.v116"
  )

  if (db_path == "" || !file.exists(db_path)) {
    packageStartupMessage(
      "EnsDb.Hsapiens.v116: WARNING -- no built database found in this ",
      "installation. This normally should not happen; the database is ",
      "reassembled automatically at install time. Calling ",
      "EnsDb.Hsapiens.v116() will fail until this is resolved -- see the ",
      "package README."
    )
  }
}
