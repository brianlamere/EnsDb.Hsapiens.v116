#' EnsDb.Hsapiens.v116: Ensembl 116 Annotation Database for Homo sapiens
#'
#' An \code{EnsDb} object (see the \pkg{ensembldb} package), backed by a
#' SQLite database built directly from the Ensembl release 116 GTF for
#' \emph{Homo sapiens} / GRCh38. See \code{system.file("scripts",
#' "build_ensdb.R", package = "EnsDb.Hsapiens.v116")} for the full,
#' reproducible build procedure used to generate the underlying database.
#'
#' This object is instantiated once when the package is loaded, and is
#' usable directly -- e.g. \code{seqinfo(EnsDb.Hsapiens.v116)} or
#' \code{GetGRangesFromEnsDb(ensdb = EnsDb.Hsapiens.v116)} -- without
#' calling it as a function. This matches the convention used by
#' Bioconductor's \code{EnsDb.Hsapiens.vNN} series (\code{v75}, \code{v79},
#' \code{v86}), where the package name itself resolves to the \code{EnsDb}
#' object, not a constructor. This package is an independently maintained
#' continuation of that naming convention for a release Bioconductor's
#' series has not reached; it is not produced or endorsed by the
#' Bioconductor project.
#'
#' @format An object of class \code{EnsDb}.
#' @examples
#' \dontrun{
#' ensembldb::genes(EnsDb.Hsapiens.v116)
#' }
#' @export
EnsDb.Hsapiens.v116 <- NULL  # placeholder; real object assigned in .onLoad

#' @keywords internal
.build_EnsDb.Hsapiens.v116 <- function() {
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
.onLoad <- function(libname, pkgname) {
  db_path <- system.file(
    "extdata", "EnsDb.Hsapiens.v116.sqlite",
    package = pkgname
  )

  if (db_path == "" || !file.exists(db_path)) {
    # Leave EnsDb.Hsapiens.v116 as NULL; .onAttach's warning covers this,
    # and accessing the NULL object will fail with a clear-enough error
    # from seqinfo()/genes()/etc. rather than this package trying to be
    # clever about it.
    return(invisible(NULL))
  }

  ns <- asNamespace(pkgname)
  assign("EnsDb.Hsapiens.v116", ensembldb::EnsDb(db_path), envir = ns)
  invisible(NULL)
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
      "reassembled automatically at install time. EnsDb.Hsapiens.v116 ",
      "will not be usable until this is resolved -- see the package README."
    )
  }
}
