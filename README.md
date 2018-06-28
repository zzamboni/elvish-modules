
# Table of Contents

1.  [zzamboni's Elvish libraries](#org5c1a138)
2.  [Modules](#org8971133)



<a id="org5c1a138"></a>

# zzamboni's Elvish libraries

This Elvish package contains various modules I have written for the
Elvish shell, except for [themes](https://github.com/zzamboni/elvish-themes/) and [completions](https://github.com/zzamboni/elvish-completions), which are kept in
separate packages.

To install, use [epm](https://elvish.io/ref/epm.html):

    use epm
    epm:install github.com/zzamboni/elvish-modules

For each module you want to use, you need to run `use <modulename>` in
your `rc.elv` file.

The following modules are included (you can see detailed usage
instructions in each module):


<a id="org8971133"></a>

# Modules

-   **[alias](alias.md):** Implementation of aliases for [Elvish](http://elvish.io).

-   **[bang-bang](bang-bang.md):** Implement the `!!` (last command), `!$` (last argument of last command) and `!<n>` (nth argument of last command) shortcuts in Elvish.

-   **[dir](dir.md):** Keep and move through the directory history, including a graphical chooser, similar to Elvish's Location mode, but showing a chronological directory history instead of a weighted one.

-   **[long-running-notifications](long-running-notifications.md):** Produce notifications for long-running commands in Elvish.

-   **[nix](nix.md):** Functions to set up the Nix environment variables for Elvish.

-   **[opsgenie](opsgenie.md):** This module implements a few common operations for the [OpsGenie API](https://docs.opsgenie.com/docs/api-overview) in Elvish.

-   **[prompt-hooks](prompt-hooks.md):** Convenience functions to add hooks to the prompt hook lists.

-   **[proxy](proxy.md):** Manipulation of proxy-related environment variables (including auto-setting/unsetting based on a user-defined test) for [Elvish](http://elvish.io).

-   **[semver](semver.md):** Comparison of semantic version numbers, as described in [the Semantic Versioning specification](https://semver.org/#spec-item-11).

-   **[terminal-title](terminal-title.md):** Sets the terminal title dynamically using ANSI escape codes. By default the current directory is shown, and the name of the current command while one is executing.

-   **[test](test.md):** A very simplistic test framework for Elvish.

-   **[util](util.md):** Various utility functions.
