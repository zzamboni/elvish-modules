use builtin
use narrow

before-chooser = []
after-chooser = []

max-stack-size = 100

-dirstack = [ $pwd ]
-cursor = (- (count $-dirstack) 1)

fn -trimstack {
  -dirstack = $-dirstack[0:(+ $-cursor 1)]
}

fn stack { put $@-dirstack }

fn stacksize { count $-dirstack }

fn history {
  for index [(range 0 (stacksize))] {
    if (== $index $-cursor) {
      echo (styled "* "$-dirstack[$index] green)
    } else {
      echo "  "$-dirstack[$index]
    }
  }
}

fn curdir {
  if (> (stacksize) 0) {
    put $-dirstack[$-cursor]
  } else {
    put ""
  }
}

fn push {
  if (or (== (stacksize) 0) (!=s $pwd (curdir))) {
    -dirstack = [ (explode $-dirstack[0:(+ $-cursor 1)]) $pwd ]
    if (> (stacksize) $max-stack-size) {
      -dirstack = $-dirstack[(- $max-stack-size):]
    }
    -cursor = (- (stacksize) 1)
  }
}

fn back {
  if (> $-cursor 0) {
    -cursor = (- $-cursor 1)
    builtin:cd $-dirstack[$-cursor]
  } else {
    echo "Beginning of directory history!" > /dev/tty
  }
}

fn forward {
  if (< $-cursor (- (stacksize) 1)) {
    -cursor = (+ $-cursor 1)
    builtin:cd $-dirstack[$-cursor]
  } else {
    echo "End of directory history!" > /dev/tty
  }
}

fn pop {
  if (> $-cursor 0) {
    back
    -trimstack
  } else {
    echo "No previous directory to pop!" > /dev/tty
  }
}

fn cd [@dir]{
  if (and (== (count $dir) 1) (eq $dir[0] "-")) {
    builtin:cd $-dirstack[(- $-cursor 1)]
  } else {
    builtin:cd $@dir
  }
}

fn cdb [p]{ cd (dirname $p) }

fn left-word-or-prev-dir {
  if (> (count $edit:current-command) 0) {
    edit:move-dot-left-word
  } else {
    back
  }
}

fn right-word-or-next-dir {
  if (> (count $edit:current-command) 0) {
    edit:move-dot-right-word
  } else {
    forward
  }
}

fn left-small-word-or-prev-dir {
  if (> (count $edit:current-command) 0) {
    edit:move-dot-left-small-word
  } else {
    back
  }
}

fn right-small-word-or-next-dir {
  if (> (count $edit:current-command) 0) {
    edit:move-dot-right-small-word
  } else {
    forward
  }
}

fn history-chooser {
  for hook $before-chooser { $hook }
  index = 0
  candidates = [(each [arg]{
        put [
          &content=$arg
          &display=$index" "$arg
          &filter-text=$index" "$arg
        ]
        index = (+ $index 1)
  } $-dirstack)]
  edit:-narrow-read {
    put $@candidates
  } [arg]{
    builtin:cd $arg[content]
    for hook $after-chooser { $hook }
  } &modeline="Dir history " &ignore-case=$true &keep-bottom=$true
}

fn init {
  after-chdir = [ $@after-chdir [dir]{ push } ]
}

init
