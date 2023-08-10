
Svlint Installer
================

Makefile-based system for building `svlint` and `svls` from source, then
installing onto a shared filesystem with
[Envirorment Modules](https://modules.readthedocs.io/en/latest/index.html).

You should build from source if you want to maintain a custom branch, perhaps
with non-public configuration and/or additional functionality.
If you don't need to build from source, you can use the [released ZIP
archive](https://github.com/dalance/svlint/releases/tag/v0.9.0).
The main difference is that the ZIP does not include a modulefile or svls.

These instructions assume that you have cloned this repository, `cd`'d to its
directory, and checked out a tag.

```sh
$ git clone https://github.com/DaveMcEwan/svlint_installer
$ cd svlint_installer
$ git checkout v0.9.0
```

Tags on the master branch of this repository should reflect the reference tag
on the [https://github.com/dalance/svlint](svlint repository).
Tags on other branches should be prefixed by the respective branch name.


Simple Installation
-------------------

```sh
$ make
$ make install
```

The first command (`make`) will fetch, patch, and compile the Rust source code
into executable binaries - This may take a while.
The second command (`make install`) produces a modulefile and copies the
binaries, documentation, and modulefile to a target location.
Optionally, you can perform everything in one step by simply using the second
command (`make install`).

Now, you should see all installed files under one directory:
```
$ cd ${HOME}/svlint_v0.9.0/
$ find -type f
./bin/svlint
./bin/svls
./bin/designintent.toml
./bin/parseonly.toml
# ... snipped *.toml configurations
./bin/svlint-designintent
./bin/svlint-parseonly
# ... snipped svlint-* wrapper scripts
./bin/svls-designintent
./bin/svls-parseonly
# ... snipped svls-* wrapper scripts
./doc/svlint_MANUAL_v0.9.0.md
./doc/svlint_MANUAL_v0.9.0.pdf
./modulefiles/svlint-v0.9.0
```


Complex Installation
--------------------

A more realistic usage of this repository is where the binaries, documentation,
and modulefile need to be placed in different locations.
For example, documentation and binaries under one directory, e.g.
`/cad/tools/svlint/v0.9.0/doc/*` and `/cad/tools/svlint/v0.9.0/bin/*`, and
modulefiles in another, e.g. `/cad/modules/modulefiles/svlint/svlint-v0.9.0`.

```
$ make \
    INSTALL_DOC=/cad/tools/svlist/v0.9.0/doc \
    INSTALL_BIN=/cad/tools/svlist/v0.9.0/bin \
    INSTALL_MODULEFILES=/cad/modules/modulefiles/svlint \
    install
```

Users can make use of that example module installation in two steps.
First, setup the GNU Modulefiles system in their `~/.bashrc` (or similar) like
`module use /cad/modules/modulefiles`.
Second, configure each shell to use a particular version of svlint like
`module load svlint/svlint-v0.9.0` or `module load svlint/svlint-custom1.2.3`.
