# Git and vcsh related functions

use re

# Check if the current directory is a git repo
fn is-git-repo {
  put ?(git rev-parse --is-inside-work-tree >/dev/null 2>/dev/null)
}

# Wrapper around git that transparenly calls vcsh if the current
# directory is not a git repo, but it is a vcsh-managed directory.
fn git-vcsh {|@arg|
  if (is-git-repo) {
    # If we are in a git repo, run git normally
    try {
      e:git $@arg
    } except e {
      if (not (re:match 'git killed by signal broken pipe' (echo $e))) {
        fail (echo $e)
      }
    }
  } else {
    # Else, try to determine if we are in a vcsh-managed directory
    var dirname = (path-base $pwd)
    var vcsh-repo = ""
    pwd=~ { set _ = ?(set vcsh-repo = (splits ':' (vcsh which $dirname 2>/dev/null | take 1) | take 1)) }
    if (not-eq $vcsh-repo "") {
      # If the last git argument is "status", add a "." to restrict the status to the current directory
      # and avoid spurious output from vcsh
      if (or (==s $arg[-1] "status") (==s $arg[-1] "st")) {
        set arg = [$@arg "."]
      }
      # Execute vcsh with the correct repo and the git options given
      vcsh $vcsh-repo $@arg
    } else {
      # If this is no vcsh dir, run git anyway, which will produce the expected error
      e:git $@arg
    }
  }
}
