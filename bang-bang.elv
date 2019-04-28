before-lastcmd = []
after-lastcmd = []

-plain-bang-insert = ""

-extra-trigger-keys = []

fn insert-plain-bang { edit:insert:start; edit:insert-at-dot "!" }

fn lastcmd {
  for hook $before-lastcmd { $hook }
  last = (edit:command-history -1)
  parts = [(edit:wordify $last[cmd])]
  use ./util
  
  nitems = (count $parts)
  indicator-width = (util:max (count $nitems) (count $-plain-bang-insert))
  filler = (repeat $indicator-width ' ' | joins '')
  fn -display-text [ind text]{
    indcol = $filler$ind
    put $indcol[(- $indicator-width):]" "$text
  }
  cmd = [
    &content=     $last[cmd]
    &display=     (-display-text "!" $last[cmd])
    &filter-text= $last[cmd]
  ]
  bang = [
    &content=     "!"
    &display=     (-display-text $-plain-bang-insert "!")
    &filter-text= "!"
  ]
  items = [
    (range $nitems |
      each [i]{
        text = $parts[$i]
        if (eq $i (- $nitems 1)) {
          i = "$"
        } elif (> $i 9) {
          i = ""
        }
        put [
          &content=     $text
          &display=     (-display-text $i $text)
          &filter-text= $text
        ]
      }
    )
  ]
  candidates = [$cmd $@items $bang]
  fn insert-full-cmd { edit:insert:start; edit:insert-at-dot $last[cmd] }
  fn insert-part [n]{ edit:insert:start; edit:insert-at-dot $parts[$n] }
  bindings = [
    &!=                   $insert-full-cmd~
    &"$"=                 { insert-part -1 }
    &$-plain-bang-insert= $insert-plain-bang~
  ]
  for k $-extra-trigger-keys {
    bindings[$k] = $insert-full-cmd~
  }
  range (util:min (count $parts) 10) | each [i]{
    bindings[(to-string $i)] = { insert-part $i }
  }
  edit:-narrow-read {
    put $@candidates
  } [arg]{
    edit:insert-at-dot $arg[content]
    for hook $after-lastcmd { $hook }
  } &modeline="bang-bang " &auto-commit=$true &ignore-case=$true &bindings=$bindings
}

fn init [&plain-bang="Alt-!" &extra-triggers=["Alt-1"]]{
  -plain-bang-insert = $plain-bang
  -extra-trigger-keys = $extra-triggers
  edit:insert:binding[!] = $lastcmd~
  for k $extra-triggers {
    edit:insert:binding[$k] = $lastcmd~
  }
  edit:insert:binding[$-plain-bang-insert] = $insert-plain-bang~
}

init
