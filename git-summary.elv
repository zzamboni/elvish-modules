use path
use github.com/zzamboni/elvish-modules/spinners

use github.com/zzamboni/elvish-themes/chain

var summary-repos = []

var find-all-user-repos-fn = {
  fd -H -I -t d '^.git$' ~ | each $path:dir~
}

var repos-file = ~/.elvish/package-data/elvish-themes/git-summary-repos.json

var stop-gitstatusd-after-use = $false

fn -write-summary-repos {
  mkdir -p (path:dir $repos-file)
  to-json [$summary-repos] > $repos-file
}

fn -read-summary-repos {
  try {
    set summary-repos = (from-json < $repos-file)
  } except {
    set summary-repos = []
  }
}

fn gather-data {|repos|
  each {|r|
    try {
      cd $r
      chain:-parse-git &with-timestamp
      var status = [($chain:segment[git-combined])]
      put [
        &repo= (tilde-abbr $r)
        &status= $status
        &ts= $chain:last-status[timestamp]
        &timestamp= ($chain:segment[git-timestamp])
        &branch= ($chain:segment[git-branch])
      ]
    } except e {
      put [
        &repo= (tilde-abbr $r)
        &status= [(styled '['(to-string $e)']' red)]
        &ts= ""
        &timestamp= ""
        &branch= ""
      ]
    }
  } $repos
  if $stop-gitstatusd-after-use {
    # Temporarily disable background job notifications
    var old-notify-bg-job-success = $notify-bg-job-success
    set notify-bg-job-success = $false
    chain:gitstatus:stop
    sleep 0.01
    set notify-bg-job-success = $old-notify-bg-job-success
  }
}

fn summary-status {|@repos &all=$false &only-dirty=$false|
  var prev = $pwd

  # Determine how to sort the output. This only happens in newer
  # versions of Elvish (where the order function exists)
  use builtin
  var order-cmd~ = $all~
  if (has-key $builtin: order~) {
    set order-cmd~ = { order &less-than={|a b| <s $a[ts] $b[ts] } &reverse }
  }

  # Read repo list from disk, cache in $git-summary:summary-repos
  -read-summary-repos

  # Determine the list of repos to display:
  # 1) If the &all option is given, find them
  if $all {
    spinners:run &title="Finding all git repos" &style=blue {
      set repos = [($find-all-user-repos-fn)]
    }
  }
  # 2) If repos is not given nor defined through &all, use $git-summary:summary-repos
  if (eq $repos []) {
    set repos = $summary-repos
  }
  # 3) If repos is specified, just use it

  # Produce the output
  spinners:run &title="Gathering repo data" &style=blue { gather-data $repos } | order-cmd | each {|r|
    var status-display = $r[status]
    if (or (not $only-dirty) (not-eq $status-display [])) {
      if (eq $status-display []) {
        var color = (chain:-segment-style git-combined)
        set status-display = [(chain:-colorized "[" $color) (styled OK green) (chain:-colorized "]" $color)]
      }
      var @status = $r[timestamp] ' ' (all $status-display) ' ' $r[branch]
      echo &sep="" $@status ' ' (chain:-colorized $r[repo] (chain:-segment-style git-repo))
    }
  }
  cd $prev
}

fn add-repo {|@dirs|
  if (eq $dirs []) {
    set dirs = [ $pwd ]
  }
  -read-summary-repos
  each {|d|
    if (has-value $summary-repos $d) {
      echo (styled "Repo "$d" is already in the list" yellow)
    } else {
      set summary-repos = [ $@summary-repos $d ]
      echo (styled "Repo "$d" added to the list" green)
    }
  } $dirs
  -write-summary-repos
}

fn remove-repo {|@dirs|
  if (eq $dirs []) {
    set dirs = [ $pwd ]
  }
  -read-summary-repos
  var @new-repos = (each {|d|
      if (not (has-value $dirs $d)) { put $d }
  } $summary-repos)
  each {|d|
    if (has-value $summary-repos $d) {
      echo (styled "Repo "$d" removed from the list." green)
    } else {
      echo (styled "Repo "$d" was not on the list" yellow)
    }
  } $dirs

  set summary-repos = $new-repos
  -write-summary-repos
}
