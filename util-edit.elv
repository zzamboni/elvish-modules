electric-pairs = ['()' '{}' '[]' '""' "''"]

electric-pair-always = $false

fn -should-insert-pair {
  at-end = (== $edit:-dot (count $edit:current-command))
  at-space = $false
  at-closing = $false
  if (not $at-end) {
    at-space = (eq $edit:current-command[$edit:-dot] ' ')
    at-closing = (or (each [p]{ eq $edit:current-command[$edit:-dot] $p[1] } $electric-pairs))
  }
  or $electric-pair-always $at-end $at-space $at-closing
}

fn -electric-insert-fn [pair]{
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
