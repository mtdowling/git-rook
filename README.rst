========
git-rook
========

A git hook runner that can be used to execute multiple hooks in a git
repository.


Synopsis
--------

::

    git rook --install [-f|--force] [<target-directory>]
    git rook --init [-f|--force] [-n|--no-remember] [<template-directory>]
    git rook --run <hook-name> <hook-args>...
    git rook --list [<target-directory>]


Description
-----------

``git-rook``, (meaning r(un h)ook), is a git hook runner that allows you to
execute multiple git hooks for the same action. By default, git hooks allow
only a single script to be executed per action (e.g., ``pre-commit``,
``commit-msg``, etc.).

``git-rook`` installs the scripts necessary to enable you to execute
multiple scripts per action by installing the ``git-rook`` hooks for a
repository and then adding scripts to the hook's corresponding
``<hook-name>.d`` directory.

For example, let's say we want to execute multiple hooks for the pre-commit
git hook. First we need to install ``git-rook`` hooks into the
repository::

    cd /path/to/my/repo
    git rook --install

Produces the following output::

    ✓ Hooks installed to git repository at .

Next we need to add our hook to the appropriate hook directory::

    echo '#!/usr/bin/env bash' > .git/hooks/pre-commit.d/hook.sh
    echo 'echo "Hello!"; exit 1' >> .git/hooks/pre-commit.d/hook.sh
    chmod +x .git/hooks/pre-commit.d/hook.sh

Now when we commit to our repository, we will see the word 'Hello!' and see
that the commit was prevented due to a failing pre-commit hook::

    git commit -m 'Testing...'

Produces the following output::

    ✗ pre-commit.d/hook.sh exit code 1, output:
      Hello!
    Ran 1 pre-commit hooks, 1 failed

You can place any number of hooks into the ``pre-commit.d`` directory, and they
will all be executed. ``git-rook`` will create these ``<hook-name>.d``
directories for each hook that git supports. See the
`git documention <https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks>`_
for a full list of hooks.

In addition to the built-in git hooks, ``git rook`` also supports the
``post-init`` hook when running ``git rook --init``. This hook allows you to
run commands when initializing a git repository (either to create one or to
sync template files into a repository).


Installing git-rook
~~~~~~~~~~~~~~~~~~~

You can try using ``make install`` to install ``git-rook``. ``git-rook`` is
installed by copying ``git-rook`` to somewhere in your ``$PATH``. This will
then allow you to run ``git rook``, enabling the use of managed git hooks.

You can also install the man page for ``git-rook`` by copying ``git-rook.1``
to a directory in one of your configured man paths
(e.g., ``/usr/local/share/man/man1``).


Options
-------

Operation Modes
~~~~~~~~~~~~~~~

Each of these options must appear first on the command line.

--install
    Installs ``git-rook`` hooks for a repository or git template.

--init
    Copies template-directory template into repo-directory and runs the
    post-init hook.

--run
    Runs a git hook

--list
    Lists hooks installed the <target-directory> (assumes current directory)


Options for ``--install``
~~~~~~~~~~~~~~~~~~~~~~~~~

-f, --force
    Overwrites any existing hooks found in ``repo-directory`` or
    ``template-directory``

<target-directory>
    Installs git hooks to the given ``target-directory``. The current directory
    is assumed if no ``target-directory`` is not provided.

    If ``target-directory`` contains a ``.git`` directory, hooks will be
    installed to ``<target-directory>/.git/hooks``. Otherwise,
    ``target-directory`` will be created and hooks will be installed to
    ```<target-directory>/hooks``. This is useful for creating git templates.


Examples
^^^^^^^^

Install hooks for a repository::

    git rook --install -f /path/to/my/repo

Install hooks for a repository and overwrite any existing hooks::

    git rook --install -f /path/to/my/repo

Create a git template with ``git-rook`` hooks configured::

    git rook --install ~/.git-templates/my-template

Create a git template with ``git-rook`` hooks configured and overwrite
any existing hooks::

    git rook --install -f ~/.git-templates/my-template


Options for ``--init``
~~~~~~~~~~~~~~~~~~~~~~

-f, --force
    Overwrites any existing hooks found in ``repo-directory`` or
    ``template-directory``

-n, --no-remember
    Prevent ``--init`` from remembering the ``--template`` by passing the
    ``-n`` option. ``--init`` will by default remember the provided
    ``--template`` by saving it in the ``init.templateDir`` git configuration
    value for the repo.

<template-directory>
    Copies the contents of the provided template into the git repository. Any
    scripts found in the ``hooks/post-init.d/`` directory of the template will
    be executed. This value is optional if ``$GIT_TEMPLATE_DIR`` is set or the
    ``init.templateDir`` git configuration value is set.


Examples
^^^^^^^^

Use a git template with a new git repository::

    mkdir /tmp/test-repo && cd /tmp/test-repo
    git rook --init ~/.git-templates/my-template

Update an existing git repository with any changes made in a template::

    # Runs any found post-init.d/ hooks
    git rook --init ~/.git-templates/my-template

    # Same as above, but does not run the hooks
    git init --template ~/.git-templates/my-template



Options for ``--run``
~~~~~~~~~~~~~~~~~~~~~~

<hook-name>
    Name of the hook to run

<args>...
    Any arguments provided after the hook name will be forwarded to the hook


Examples
^^^^^^^^

Run the ``post-init`` hook on demand::

    git rook --run post-init


Options for ``--list``
~~~~~~~~~~~~~~~~~~~~~~

<target-directory>
    Directory of a git repository or Git template.


Examples
^^^^^^^^

List hooks in a repository::

    git rook --list

List hooks in a Git template::

    git rook --list ~/.git-templates/my-template


Using templates
---------------

You can use git templates in order to pre-install ``git-rook`` for a
repository. When initializing a git repository or cloning a git repository, you
can provide the ``--template`` option with the path to a template directory on
disk. The contents of this directory will then be copied to ``$GIT_DIR``
(typically ``.git/``) after it is created.

First you'll need to create a template directory. This can be done with
``git rook --install <template-directory>``::

    git rook --install ~/.git-templates/my-template

Next you'll need to run the following command to initialize the git repository
and install the template::

    mkdir /tmp/test-repo && cd /tmp/test-repo
    git rook --init ~/.git-templates/my-template

``git rook --init <template-directory>`` is the same as running
``git init --template``, but ``git rook --init`` will run any ``post-init.d/``
hooks that might be installed in the provided template. This allows you to
execute custom commands when installing a template to a git repository.

Please note that you can run ``git init`` on a repository that has already been
initialized. From the `git documentation <https://git-scm.com/docs/git-init>`_:

    Running git init in an existing repository is safe. It will not overwrite
    things that are already there. The primary reason for rerunning git init is
    to pick up newly added templates (or to move the repository to another
    place if ``--separate-git-dir`` is given).


Skipping hooks
--------------

You can skip one or more hooks using the ``SKIP`` variable and providing it a
comma separated list of hook filenames to skip. For example, if you have a
hook named "foo.sh" and "bar" that you wish to skip for a git commit, you can
run the following command::

    SKIP=foo.sh,bar git commit -m 'Testing...'


About
------

- Author: Michael Dowling <https://github.com/mtdowling>
- Issue tracker: This project's source code and issue tracker can be found at
  `https://github.com/mtdowling/git-rook <https://github.com/mtdowling/git-rook>`_
