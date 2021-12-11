use builtin

var before-chooser = []
var after-chooser = []

var max-stack-size = 100

var -dirstack = [ $pwd ]
var -cursor = (- (count $-dirstack) 1)

fn -trimstack {
  set -dirstack = $-dirstack[0..(+ $-cursor 1)]
}

var print-message = {|msg|
  echo $msg > /dev/tty
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
    set -dirstack = [ (all $-dirstack[0..(+ $-cursor 1)]) $pwd ]
    if (> (stacksize) $max-stack-size) {
      set -dirstack = $-dirstack[(- $max-stack-size)..]
    }
    set -cursor = (- (stacksize) 1)
  }
}

fn back {
  if (> $-cursor 0) {
    set -cursor = (- $-cursor 1)
    builtin:cd $-dirstack[$-cursor]
  } else {
    $print-message "Beginning of directory history!"
  }
}

fn forward {
  if (< $-cursor (- (stacksize) 1)) {
    set -cursor = (+ $-cursor 1)
    builtin:cd $-dirstack[$-cursor]
  } else {
    $print-message "End of directory history!"
  }
}

fn pop {
  if (> $-cursor 0) {
    back
    -trimstack
  } else {
    $print-message "No previous directory to pop!"
  }
}

fn cd {|@dir|
  if (and (== (count $dir) 1) (eq $dir[0] "-")) {
    builtin:cd $-dirstack[(- $-cursor 1)]
  } else {
    builtin:cd $@dir
  }
}

fn cdb {|p| cd (dirname $p) }

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
  var index = 0
  var candidates = [(each {|arg|
        put [
          &to-accept=$arg
          &to-show=$index" "$arg
          &to-filter=$index" "$arg
        ]
        set index = (to-string (+ $index 1))
  } $-dirstack)]
  edit:listing:start-custom $candidates &caption="Dir history " &accept={|arg|
    builtin:cd $arg
    for hook $after-chooser { $hook }
  }
}

fn init {
  set after-chdir = [ $@after-chdir {|dir| push } ]
}

init
