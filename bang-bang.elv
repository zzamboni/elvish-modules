use ./util
use re
use str

before-lastcmd = []
after-lastcmd = []

-plain-bang-insert = ""

-extra-trigger-keys = []

fn insert-plain-bang { edit:close-mode; edit:insert-at-dot "!" }

fn lastcmd {
  for hook $before-lastcmd { $hook }
  last = [(edit:command-history)][-1]
  parts = [(edit:wordify $last[cmd])]
  nitems = (count $parts)
  indicator-width = (util:max (+ 2 (count $nitems)) (count $-plain-bang-insert))
  filler = (repeat $indicator-width ' ' | str:join '')
  fn -display-text [ind text]{
    indcol = $filler$ind
    put $indcol[(- $indicator-width)..]" "$text
  }
  cmd = [
    &to-accept= $last[cmd]
    &to-show=   (-display-text "!" $last[cmd])
    &to-filter= "! "$last[cmd]
  ]
  bang = [
    &to-accept= "!"
    &to-show=   (-display-text $-plain-bang-insert "!")
    &to-filter= $-plain-bang-insert" !"
  ]
  all-args = []
  arg-text = ""
  if (> $nitems 1) {
    arg-text = (str:join " " $parts[1..])
    all-args = [
      &to-accept= $arg-text
      &to-show=   (-display-text "*" $arg-text)
      &to-filter= "* "$arg-text
    ]
  }
  items = [
    (range $nitems |
      each [i]{
        text = $parts[$i]
        ind = (to-string $i)
        if (> $i 9) {
          ind = ""
        }
        if (eq $i (- $nitems 1)) {
          ind = $ind" $"
        }
        put [
          &to-accept= $text
          &to-show=   (-display-text $ind $text)
          &to-filter= $ind" "$text
        ]
      }
    )
  ]
  candidates = [$cmd $@items $all-args $bang]
  fn insert-full-cmd { edit:close-mode; edit:insert-at-dot $last[cmd] }
  fn insert-part [n]{ edit:close-mode; edit:insert-at-dot $parts[$n] }
  fn insert-args { edit:close-mode; edit:insert-at-dot $arg-text }
  bindings = [
    &"!"=                 $insert-full-cmd~
    &"$"=                 { insert-part -1 }
    &$-plain-bang-insert= $insert-plain-bang~
    &"*"=                 $insert-args~
  ]
  for k $-extra-trigger-keys {
    bindings[$k] = $insert-full-cmd~
  }
  range (util:min (count $parts) 10) | each [i]{
    bindings[(to-string $i)] = { insert-part $i }
  }
  bindings = (edit:binding-table $bindings)
  edit:listing:start-custom $candidates &caption="bang-bang " &binding=$bindings &accept=[arg]{
    edit:insert-at-dot $arg
    for hook $after-lastcmd { $hook }
  }
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
