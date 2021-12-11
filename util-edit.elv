fn -electric-insert-fn {|pair|
  put {
    if (-should-insert-pair) {
      edit:insert-at-dot $pair
      edit:move-dot-left
    } else {
      edit:insert-at-dot $pair[0]
    }
  }
}

fn -electric-backspace {
  if (> $edit:-dot 0) {
    var char1 = ''
    var char2 = ''
    # To get the previous character, loop through the indices in case
    # the previous character is multi-byte
    var i = (- $edit:-dot 1)
    while (not ?(set char1 = $edit:current-command[$i])) { set i = (- $i 1) }
    if (< $edit:-dot (count $edit:current-command)) {
      set char2 = $edit:current-command[$edit:-dot]
    }
    var pending-delete = $true
    for pair $electric-pairs {
      if (and (==s $char1 $pair[0]) (==s $char2 $pair[1])) {
        edit:kill-rune-left
        edit:kill-rune-right
        set pending-delete = $false
      }
    }
    if $pending-delete {
      edit:kill-rune-left
    }
  }
}

fn electric-delimiters {
  for pair $electric-pairs {
    set edit:insert:binding[$pair[0]] = (-electric-insert-fn $pair)
  }
  set edit:insert:binding[Backspace] = $-electric-backspace~
}

fn -electric-backspace {
  if (> $edit:-dot 0) {
    char1 = ''
    char2 = ''
    # To get the previous character, loop through the indices in case
    # the previous character is multi-byte
    i = (- $edit:-dot 1)
    while (not ?(char1 = $edit:current-command[$i])) { i = (- $i 1) }
    if (< $edit:-dot (count $edit:current-command)) {
      char2 = $edit:current-command[$edit:-dot]
    }
    pending-delete = $true
    for pair $electric-pairs {
      if (and (==s $char1 $pair[0]) (==s $char2 $pair[1])) {
        edit:kill-rune-left
        edit:kill-rune-right
        pending-delete = $false
      }
    }
    if $pending-delete {
      edit:kill-rune-left
    }
  }
}

fn electric-delimiters {
  for pair $electric-pairs {
    edit:insert:binding[$pair[0]] = (-electric-insert-fn $pair)
  }
  edit:insert:binding[Backspace] = $-electric-backspace~
}
