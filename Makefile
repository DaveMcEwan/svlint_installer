
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
REVISION_SVPARSER ?= v0.12.2
REVISION_SVLINT		?= v0.6.1
REVISION_SVLS			?= v0.2.6

# Before any installation, all files are copied to somewhere under the ${BUILD}
# directory.
# NOTE: If this is set to `build`, then neither `make` or `make build` will
# work as intended.
THIS ?= $(realpath $(shell pwd))
BUILD ?= $(realpath $(shell pwd))/out

install_topdefault := ${HOME}/svlint_${TAG}
# `INSTALL_*` variables are used by the `install_` recipes as the destination
# for files to be copied from ${BUILD}, the only source.
# It is not required for the doc, bin, and modulefiles pieces to be copied
# under a common ancestor.
# It is intended that branches of this repo will change these destinations to
# something else, for example `INSTALL_BIN=/cad/bin/svlint/${TAG}/bin` and
# `INSTALL_MODULEFILES=/projects/modulefiles/svlint_${TAG}`.
# TODO
INSTALL_DOC ?= ${install_topdefault}/doc
INSTALL_BIN ?= ${install_topdefault}/bin
INSTALL_MODULEFILES ?= ${install_topdefault}/modulefiles

# Download component repositories, then checkout a specific revision.
# {{{ fetch

.PHONY: fetch
fetch: ${BUILD}/fetch_svparser
fetch: ${BUILD}/fetch_svlint
fetch: ${BUILD}/fetch_svls

${BUILD}/fetch_svparser: | ${BUILD}
	git clone ${REPO_SVPARSER}
	cd sv-parser && git checkout ${REVISION_SVPARSER}
	cd sv-parser && git describe --tags --always > $@
	date >> $@

${BUILD}/fetch_svlint: | ${BUILD}
	git clone ${REPO_SVLINT}
	cd svlint && git checkout ${REVISION_SVLINT}
	cd svlint && git describe --tags --always > $@
	date >> $@

${BUILD}/fetch_svls: | ${BUILD}
	git clone ${REPO_SVLS}
	cd svls && git checkout ${REVISION_SVLS}
	cd svls && git describe --tags --always > $@
	date >> $@

# }}} fetch

# Apply any changes to the source.
# {{{ patch

.PHONY: patch
patch: ${BUILD}/patch_svparser
patch: ${BUILD}/patch_svlint
patch: ${BUILD}/patch_svls

PATCHFILE_SVPARSER := ${THIS}/svparser.patch
PATCHFILE_SVLINT := ${THIS}/svlint.patch
PATCHFILE_SVLS := ${THIS}/svls.patch

${BUILD}/patch_svparser: ${PATCHFILE_SVPARSER}
${BUILD}/patch_svparser: ${BUILD}/fetch_svparser
	(grep -q '.+' ${PATCHFILE_SVPARSER} && \
		cd sv-parser && git apply ${PATCHFILE_SVPARSER} && \
		echo "applied ${PATCHFILE_SVPARSER}" > $@ \
		) || \
		echo "unused ${PATCHFILE_SVPARSER}" > $@
	date >> $@

${BUILD}/patch_svlint: ${PATCHFILE_SVLINT}
${BUILD}/patch_svlint: ${BUILD}/fetch_svlint
	(grep -q '.+' ${PATCHFILE_SVLINT} && \
		cd svlint && git apply ${PATCHFILE_SVLINT} && \
		echo "applied ${PATCHFILE_SVLINT}" > $@ \
		) || \
		echo "unused ${PATCHFILE_SVLINT}" > $@
	date >> $@

${BUILD}/patch_svls: ${PATCHFILE_SVLS}
${BUILD}/patch_svls: ${BUILD}/fetch_svls
	(grep -q '.+' ${PATCHFILE_SVLS} && \
		cd svls && git apply ${PATCHFILE_SVLS} && \
		echo "applied ${PATCHFILE_SVLS}" > $@ \
		) || \
		echo "unused ${PATCHFILE_SVLS}" > $@
	date >> $@

# }}} patch

# Use cargo to compile binary executables, write a modulefile, convert
# manual(s) to PDF, and copy results to ${BUILD}.
# {{{ build

# Files produced under `build/` can come from a variety of sources, e.g.
# `build/bin/svlint` is copied from under `svlint/target/release/...` and
# `build/modulefiles/svlint_v0.6.1` is written directly from this Makefile.
build_doc := ${BUILD}/doc
build_bin := ${BUILD}/bin
build_modulefiles := ${BUILD}/modulefiles

md_svlint := ${build_doc}/svlint_${REVISION_SVLINT}_manual.md
pdf_svlint := ${build_doc}/svlint_${REVISION_SVLINT}_manual.pdf
exe_svlint := ${build_bin}/svlint
exe_svls := ${build_bin}/svls
modulefile := ${build_modulefiles}/svlint_${TAG}

.PHONY: build
build: ${md_svlint}
build: ${pdf_svlint}
build: ${exe_svlint}
build: ${exe_svls}
build: ${modulefile}

${BUILD}:
	mkdir -p ${BUILD}
${build_bin}:
	mkdir -p ${build_bin}
${build_doc}:
	mkdir -p ${build_doc}
${build_modulefiles}:
	mkdir -p ${build_modulefiles}

${md_svlint}: ${BUILD}/patch_svlint
${md_svlint}: | ${build_doc}
	cp svlint/MANUAL.md $@

${pdf_svlint}: ${BUILD}/patch_svlint
${pdf_svlint}: | ${build_doc}
	pandoc -f svlint/MANUAL.md -t $@

${exe_svlint}: ${BUILD}/patch_svparser
${exe_svlint}: ${BUILD}/patch_svlint
${exe_svlint}: | ${build_bin}
	cd svlint && cargo build --release
	cp svlint/target/release/svlint $@
	cp svlint/rulesets/*.toml ${build_bin}
	find svlint/rulesets/ -type f -perm -u=x -exec cp {} ${build_bin} +

${exe_svls}: ${BUILD}/patch_svparser
${exe_svls}: ${BUILD}/patch_svlint
${exe_svls}: ${BUILD}/patch_svls
${exe_svls}: | ${build_bin}
	cd svls && cargo build --release
	cp svls/target/release/svls $@

# Convenience variable, used to get newline characters out of this Makefile.
define newline


endef

# https://modules.readthedocs.io/en/latest/modulefile.html
define body_modulefile
#%Module

set TAG "svlint_installer ${TAG}"

proc ModulesHelp {} {
  global TAG
  puts stderr "\tAdd svlint/svls to you environment, packaged by $$TAG."
	puts stderr "\t<https://github.com/DaveMcEwan/svlint_installer>"
}

module-whatis "SystemVerilog (IEEE1800-2017) linter and LSP server."

prepend-path PATH "${INSTALL_BIN}"
endef

# NOTE: Given that you're using GNU/Modulefiles, it's reasonable to assume
# you're using a version of `echo` that supports `-e`.
${modulefile}: | ${build_modulefiles}
	echo -e '$(subst ${newline},\n,${body_modulefile})' > $@

# }}} build

# Copy built files to their intended destination.
# {{{ install

.PHONY: install install_bin install_doc install_modulefiles
install: install_doc
install: install_bin
install: install_modulefiles

install_doc:
	mkdir -p ${INSTALL_BIN}
	cp ${build_bin}/* ${INSTALL_BIN}/

install_bin:
	mkdir -p ${INSTALL_DOC}
	cp ${build_doc}/* ${INSTALL_DOC}/

install_modulefiles:
	mkdir -p ${INSTALL_MODULEFILES}
	cp ${build_modulefiles}/* ${INSTALL_MODULEFILES}/

# }}} install

.PHONY: clean
clean:
	rm -rf ${BUILD}

