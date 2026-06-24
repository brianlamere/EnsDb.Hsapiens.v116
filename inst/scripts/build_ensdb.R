#!/usr/bin/env Rscript
#
# build_ensdb.R
#
# Reproducible build script for EnsDb.Hsapiens.v116.
#
# This script is the entire "recipe" for this package's data. It is not run
# automatically on install. Run it once, explicitly, before R CMD build /
# R CMD INSTALL, or any time you want to regenerate the SQLite database from
# scratch to confirm reproducibility.
#
# What it does:
#   1. Downloads the Ensembl release 116 GTF for Homo sapiens / GRCh38 from
#      the official Ensembl FTP site, into a temp directory (nothing is
#      cached outside this package's own inst/extdata/ when finished).
#   2. Verifies the download against Ensembl's published CHECKSUMS file
#      (CRC + block-count, the classic Unix `sum` algorithm Ensembl uses)
#      so a corrupted or tampered download is caught rather than silently
#      built into the package.
#   3. Calls ensembldb::ensDbFromGtf() to build the SQLite EnsDb database,
#      writing it directly into inst/extdata/, where the package's loader
#      function expects to find it.
#
# Re-running this script at any future date, against the same pinned URL,
# should reproduce a database with identical content (Ensembl numbered
# releases are not mutated after publication). If Ensembl ever changes how
# release-116 files are packaged, that is a tooling change, not a change to
# the underlying input -- see README for the project's stance on this.

ensembl_release  <- "116"
species_dir      <- "homo_sapiens"
gtf_filename     <- sprintf("Homo_sapiens.GRCh38.%s.gtf.gz", ensembl_release)
gtf_url          <- sprintf(
  "https://ftp.ensembl.org/pub/release-%s/gtf/%s/%s",
  ensembl_release, species_dir, gtf_filename
)
checksums_url    <- sprintf(
  "https://ftp.ensembl.org/pub/release-%s/gtf/%s/CHECKSUMS",
  ensembl_release, species_dir
)

out_dir   <- file.path("inst", "extdata")
out_file  <- file.path(out_dir, sprintf("EnsDb.Hsapiens.v%s.sqlite", ensembl_release))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

work_dir  <- tempdir()
gtf_path  <- file.path(work_dir, gtf_filename)

message("== EnsDb.Hsapiens.v", ensembl_release, " build ==")
message("Downloading: ", gtf_url)
download.file(gtf_url, gtf_path, mode = "wb", quiet = FALSE)

# --- Verify against Ensembl's CHECKSUMS file -------------------------------
# Ensembl publishes a CHECKSUMS file alongside each release directory using
# the classic BSD/SysV `sum` (cksum-style) algorithm, not MD5/SHA. We fetch
# it fresh each time rather than hardcoding a value, since pinning to a
# stale hardcoded checksum would itself become a silent point of failure if
# anyone ever needs to re-derive this for a different file. The pinned
# *input* is the release number and filename; the checksum is fetched
# alongside it as a verification step, exactly as Ensembl intends it to be
# used.

message("Verifying checksum against: ", checksums_url)
checksums_path <- file.path(work_dir, "CHECKSUMS")
download.file(checksums_url, checksums_path, mode = "wb", quiet = TRUE)

checksums <- readLines(checksums_path)
expected_line <- grep(gtf_filename, checksums, fixed = TRUE, value = TRUE)

if (length(expected_line) != 1) {
  stop(
    "Could not find a unique CHECKSUMS entry for ", gtf_filename,
    ". Found ", length(expected_line), " matching line(s). ",
    "Build aborted -- verify manually before proceeding."
  )
}

# CHECKSUMS line format: "<sum> <blocks> <filename>"
expected_sum    <- strsplit(trimws(expected_line), "\\s+")[[1]][1]
expected_blocks <- strsplit(trimws(expected_line), "\\s+")[[1]][2]

actual <- system2("sum", gtf_path, stdout = TRUE)
actual_parts <- strsplit(trimws(actual), "\\s+")[[1]]
actual_sum    <- actual_parts[1]
actual_blocks <- actual_parts[2]

if (!identical(actual_sum, expected_sum) || !identical(actual_blocks, expected_blocks)) {
  stop(
    "Checksum mismatch for ", gtf_filename, "!\n",
    "  Expected: sum=", expected_sum, " blocks=", expected_blocks, "\n",
    "  Actual:   sum=", actual_sum,   " blocks=", actual_blocks, "\n",
    "Do not proceed -- the download may be corrupted, truncated, or the ",
    "wrong file. Build aborted."
  )
}

message("Checksum verified OK (sum=", actual_sum, ", blocks=", actual_blocks, ")")

# --- Build the EnsDb SQLite database ---------------------------------------

if (!requireNamespace("ensembldb", quietly = TRUE)) {
  stop("Package 'ensembldb' is required to build this package. Install it ",
       "from Bioconductor first: BiocManager::install('ensembldb')")
}

message("Building EnsDb SQLite database (this can take several minutes)...")

db_path <- ensembldb::ensDbFromGtf(
  gtf            = gtf_path,
  outfile        = out_file,
  organism       = "Homo_sapiens",
  genomeVersion  = "GRCh38",
  version        = ensembl_release
)

message("Done. EnsDb SQLite database written to: ", out_file)
raw_size_mb <- round(file.info(out_file)$size / 1024^2, 1)
message("Raw SQLite size: ", raw_size_mb, " MB")

# --- Compress and chunk for GitHub storage ----------------------------------
#
# GitHub hard-blocks any single file over 100MB. Ensembl release 116 carries
# roughly a decade more annotation than v86 (whose uncompressed SQLite is
# ~349MB / ~78MB gzipped), so v116's gzipped size is genuinely uncertain
# until built -- it may land comfortably under 100MB, or may not. Rather than
# branch on a guess, this step always gzips and always splits into chunks
# safely under the limit. If the gzipped file turns out to be small enough
# for a single chunk, you'll just get one part -- no harm either way, and no
# need to re-run this differently depending on how it comes out.
#
# A SHA256 of the *reassembled, decompressed* .sqlite is written to
# extdata/EnsDb.Hsapiens.v116.sqlite.sha256 -- this is what R/zzz.R checks
# against after reassembling the chunks at load time, so a corrupted or
# incomplete reassembly is caught rather than silently producing a broken
# database.

message("Compressing and chunking for repository storage...")

gz_path <- paste0(out_file, ".gz")
sqlite_raw <- readBin(out_file, what = "raw", n = file.info(out_file)$size)
gz_con <- gzfile(gz_path, open = "wb", compression = 9)
writeBin(sqlite_raw, gz_con)
close(gz_con)

gz_size_mb <- round(file.info(gz_path)$size / 1024^2, 1)
message("Gzipped size: ", gz_size_mb, " MB")

# Record the checksum of the uncompressed database BEFORE chunking, so the
# load-time check verifies the thing that actually matters: did reassembly +
# decompression reproduce the exact bytes this build produced.
sha_path <- paste0(out_file, ".sha256")
sha_value <- system2("sha256sum", out_file, stdout = TRUE)
sha_value <- strsplit(sha_value, "\\s+")[[1]][1]
writeLines(sha_value, sha_path)
message("SQLite SHA256: ", sha_value)

chunk_size_mb <- 90  # safely under GitHub's 100MB hard limit
chunk_prefix  <- paste0(gz_path, ".part")

# Remove any stale parts from a previous build before splitting fresh.
old_parts <- list.files(out_dir, pattern = paste0(basename(chunk_prefix), "[0-9]+$"),
                         full.names = TRUE)
if (length(old_parts) > 0) unlink(old_parts)

split_result <- system2(
  "split",
  args = c("-b", paste0(chunk_size_mb, "m"), "-d", "--numeric-suffixes=1",
           shQuote(gz_path), shQuote(paste0(chunk_prefix, "."))),
  stdout = TRUE, stderr = TRUE
)

parts <- sort(list.files(out_dir, pattern = paste0(basename(chunk_prefix), "\\.[0-9]+$"),
                          full.names = TRUE))

if (length(parts) == 0) {
  stop("Splitting produced no part files -- check that `split` is available ",
       "and inspect the output above.")
}

message("Split into ", length(parts), " part(s), each <= ", chunk_size_mb, "MB:")
for (p in parts) {
  message("  ", basename(p), " (", round(file.info(p)$size / 1024^2, 1), " MB)")
}

# The full .gz is only needed transiently to produce the parts -- remove it
# so the repo only ever contains the chunked form plus the checksum, not a
# duplicate ~100MB+ file sitting alongside its own split pieces.
unlink(gz_path)

message(
  "\nBuild complete. Commit the part files and the .sha256 manifest in ",
  "inst/extdata/ -- do NOT commit the raw .sqlite or the intermediate .gz, ",
  "only the parts and the checksum."
)
message(
  "You can now run R CMD build / R CMD INSTALL on this package directory, ",
  "or devtools::install_local(), to install EnsDb.Hsapiens.v", ensembl_release, "."
)
