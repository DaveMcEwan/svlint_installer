
# TL;DR: To install svlint and svls into `$HOME/svlint_123abc`, run:
#		`make install`
# The `123abc` string is the latest tag (otherwise commit hash) on this repo.
#
# Outline of intended operation
# -----------------------------
# fetch:
#   Fetch sv-parser, svlint, svls.
# patch:
#   Apply patches to Cargo.toml for svlint, svls.
# build:
#   Use cargo to build sv-parser, then svlint, then svls.
#   Write modulefiles directly from this Makefile.
#   Convert manual(s) from Markdown to PDF.
#   Copy binaries and scripts to single directory.
#   Write modulefiles to single directory.
#   Write manual(s) to single directory.
# install:
#   Copy to destination.

# Uppercase variables are intended to be overridable, and lowercase variables
# are *not* intended to be overridden.

default: build

# An identifier for the sum of everything built here.
# Hint: Tags matching the svlint version
# https://git-scm.com/docs/git-describe
TAG ?= $(shell git describe --tags --always)

REPO_SVPARSER ?= https://github.com/dalance/sv-parser.git
REPO_SVLINT		?= https://github.com/dalance/svlint.git
REPO_SVLS			?= https://github.com/dalance/svls.git

# Revision specifiers for individual components can be branch names, tags, or
# commit hashes.
# https://git-scm.com/docs/gitrevisions
REVISION_SVPARSER ?= v0.13.1
REVISION_SVLINT		?= v0.9.0
REVISION_SVLS			?= 13ed00918b1def5d5717b3f0fa204e1e64b69ac1

# Before any installation, all files are copied to somewhere under the ${OUT}
# directory.
# NOTE: If this is set to `build`, then neither `make` or `make build` will
# work as intended.
THIS ?= $(realpath $(shell pwd))
OUT ?= $(realpath $(shell pwd))/out
IN ?= $(realpath $(shell pwd))/in

INSTALL_TOPDEFAULT ?= ${HOME}/svlint_${TAG}
# `INSTALL_*` variables are used by the `install_` recipes as the destination
# for files to be copied from ${OUT}, the only source.
# It is not required for the doc, bin, and modulefiles pieces to be copied
# under a common ancestor.
# It is intended that branches of this repo will change these destinations to
# something else, for example `INSTALL_BIN=/cad/bin/svlint/${TAG}/bin` and
# `INSTALL_MODULEFILES=/projects/modulefiles/svlint`.
INSTALL_DOC ?= ${INSTALL_TOPDEFAULT}/doc
INSTALL_BIN ?= ${INSTALL_TOPDEFAULT}/bin
INSTALL_MODULEFILES ?= ${INSTALL_TOPDEFAULT}/modulefiles

# Download component repositories, then checkout a specific revision.
# {{{ fetch

.PHONY: fetch
fetch: ${OUT}/fetch_svparser
fetch: ${OUT}/fetch_svlint
fetch: ${OUT}/fetch_svls

${IN}:
	mkdir -p ${IN}

${OUT}:
	mkdir -p ${OUT}

${OUT}/fetch_svparser: | ${IN}
${OUT}/fetch_svparser: | ${OUT}
	cd ${IN} && git clone ${REPO_SVPARSER}
	cd ${IN}/sv-parser && git checkout ${REVISION_SVPARSER}
	cd ${IN}/sv-parser && git describe --tags --always > $@
	date >> $@

${OUT}/fetch_svlint: | ${IN}
${OUT}/fetch_svlint: | ${OUT}
	cd ${IN} && git clone ${REPO_SVLINT}
	cd ${IN}/svlint && git checkout ${REVISION_SVLINT}
	cd ${IN}/svlint && git describe --tags --always > $@
	date >> $@

${OUT}/fetch_svls: | ${IN}
${OUT}/fetch_svls: | ${OUT}
	cd ${IN} && git clone ${REPO_SVLS}
	cd ${IN}/svls && git checkout ${REVISION_SVLS}
	cd ${IN}/svls && git describe --tags --always > $@
	date >> $@

# }}} fetch

# Apply any changes to the source.
# {{{ patch

.PHONY: patch
patch: ${OUT}/patch_svparser
patch: ${OUT}/patch_svlint
patch: ${OUT}/patch_svls

PATCHFILE_SVPARSER := ${THIS}/svparser.patch
PATCHFILE_SVLINT := ${THIS}/svlint.patch
PATCHFILE_SVLS := ${THIS}/svls.patch

${OUT}/patch_svparser: ${PATCHFILE_SVPARSER}
${OUT}/patch_svparser: ${OUT}/fetch_svparser
	(grep -q '.+' ${PATCHFILE_SVPARSER} && \
		cd ${IN}/sv-parser && git apply ${PATCHFILE_SVPARSER} && \
		echo "applied ${PATCHFILE_SVPARSER}" > $@ \
		) || \
		echo "unused ${PATCHFILE_SVPARSER}" > $@
	date >> $@

${OUT}/patch_svlint: ${PATCHFILE_SVLINT}
${OUT}/patch_svlint: ${OUT}/fetch_svlint
	(grep -q '.+' ${PATCHFILE_SVLINT} && \
		cd ${IN}/svlint && git apply ${PATCHFILE_SVLINT} && \
		echo "applied ${PATCHFILE_SVLINT}" > $@ \
		) || \
		echo "unused ${PATCHFILE_SVLINT}" > $@
	date >> $@

${OUT}/patch_svls: ${PATCHFILE_SVLS}
${OUT}/patch_svls: ${OUT}/fetch_svls
	(grep -q '.+' ${PATCHFILE_SVLS} && \
		cd ${IN}/svls && git apply ${PATCHFILE_SVLS} && \
		echo "applied ${PATCHFILE_SVLS}" > $@ \
		) || \
		echo "unused ${PATCHFILE_SVLS}" > $@
	date >> $@

# }}} patch

# Use cargo to compile binary executables, write a modulefile, convert
# manual(s) to PDF, and copy results to ${OUT}.
# {{{ build

# Files produced under `out/` can come from a variety of sources, e.g.
# `out/bin/svlint` is copied from under `svlint/target/release/...` and
# `out/modulefiles/svlint_v0.6.1` is written directly from this Makefile.
out_doc := ${OUT}/doc
out_bin := ${OUT}/bin
out_modulefiles := ${OUT}/modulefiles

md_svlint := ${out_doc}/svlint_MANUAL_${REVISION_SVLINT}.md
pdf_svlint := ${out_doc}/svlint_MANUAL_${REVISION_SVLINT}.pdf
exe_svlint := ${out_bin}/svlint
exe_svls := ${out_bin}/svls
modulefile := ${out_modulefiles}/svlint-${TAG}

.PHONY: build
build: ${OUT}/build_svlint
build: ${OUT}/build_svls

# NOTE: The `build` target doesn't depend on the modulefile, to allow splitting
# of the build and install stages without needing to set HOME or INSTALL_*:
#   make build
#   make install HOME=/path/to/target/dir
#build: ${OUT}/build_modulefile

${out_bin}:
	mkdir -p ${out_bin}
${out_doc}:
	mkdir -p ${out_doc}
${out_modulefiles}:
	mkdir -p ${out_modulefiles}

${OUT}/build_svlint: ${md_svlint}
${OUT}/build_svlint: ${pdf_svlint}
${OUT}/build_svlint: ${exe_svlint}
	date > $@

${OUT}/build_svls: ${exe_svls}
	date > $@

${OUT}/build_modulefile: ${modulefile}
	date > $@

${md_svlint}: ${OUT}/patch_svlint
${md_svlint}: | ${out_doc}
	cp ${IN}/svlint/MANUAL.md $@

${pdf_svlint}: ${OUT}/patch_svlint
${pdf_svlint}: | ${out_doc}
	cd ${IN}/svlint; make MANUAL-release
	cp ${IN}/svlint/MANUAL-release.pdf $@

${exe_svlint}: ${OUT}/patch_svparser
${exe_svlint}: ${OUT}/patch_svlint
${exe_svlint}: | ${out_bin}
	cd ${IN}/svlint && cargo build --release
	cp ${IN}/svlint/rulesets/*.toml ${out_bin}
	find ${IN}/svlint/rulesets/ -type f -perm -u=x -exec cp {} ${out_bin} \;
	cp ${IN}/svlint/target/release/svlint $@

${exe_svls}: ${OUT}/patch_svparser
${exe_svls}: ${OUT}/patch_svlint
${exe_svls}: ${OUT}/patch_svls
${exe_svls}: | ${out_bin}
	cd ${IN}/svls && cargo build --release
	cp ${IN}/svls/target/release/svls $@

# Convenience variable, used to get newline characters out of this Makefile.
define newline


endef

# https://modules.readthedocs.io/en/latest/modulefile.html
define body_modulefile
#%Module

set TAG "svlint_installer ${TAG}"

proc ModulesHelp {} {
  global TAG
  puts stderr "\tAdds svlint/svls to your environment, packaged by $$TAG."
	puts stderr "\t<https://github.com/DaveMcEwan/svlint_installer>"
}

module-whatis "SystemVerilog (IEEE1800-2017) linter and LSP server."

prepend-path PATH "${INSTALL_BIN}"
endef

# NOTE: Given that you're using GNU/Modulefiles, it's reasonable to assume
# you're using a version of `echo` that supports `-e`.
${modulefile}: | ${out_modulefiles}
	echo -e '$(subst ${newline},\n,${body_modulefile})' > $@

# }}} build

# Copy built files to their intended destination.
# {{{ install

.PHONY: install
install: ${OUT}/build_svlint
install: ${OUT}/build_svls
install: ${OUT}/build_modulefile
install: ${OUT}/install_doc
install: ${OUT}/install_bin
install: ${OUT}/install_modulefiles

${OUT}/install_doc:
	mkdir -p ${INSTALL_BIN}
	cp ${out_bin}/* ${INSTALL_BIN}/
	date > $@

${OUT}/install_bin:
	mkdir -p ${INSTALL_DOC}
	cp ${out_doc}/* ${INSTALL_DOC}/
	date > $@

${OUT}/install_modulefiles:
	mkdir -p ${INSTALL_MODULEFILES}
	cp ${out_modulefiles}/* ${INSTALL_MODULEFILES}/
	date > $@

# }}} install

.PHONY: clean
clean:
	rm -rf ${IN} ${OUT}

