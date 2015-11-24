PREFIX ?= /usr/local
MANPREFIX ?= "${PREFIX}/share/man/man1"

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  test     to perform unit tests."
	@echo "  man      to build the man file from README.rst"
	@echo "  install  to install the hook runner"

# We use bats for testing: https://github.com/sstephenson/bats
test:
	test/bats/bin/bats test/

# The man page is completely derived from README.rst. Edits to
# README.rst require a rebuild of the man page.
man:
	rst2man.py README.rst > git-rook.1

# Install the git-rook subcommand
install:
	@mkdir -p ${DESTDIR}${MANPREFIX}
	@mkdir -p ${DESTDIR}${PREFIX}/bin
	@cp -f git-rook ${DESTDIR}${PREFIX}/bin
	@cp -f git-rook.1 ${DESTDIR}${MANPREFIX}

.PHONY: help test man
