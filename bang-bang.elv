before-lastcmd = []
after-lastcmd = []

-plain-bang-insert = ""

-extra-trigger-keys = []

fn insert-plain-bang { edit:insert:start; edit:insert-at-dot "!" }

fn lastcmd {
  for hook $before-lastcmd { $hook }
  last = (edit:command-history -1)
  parts = [(edit:wordify $last[cmd])]
  cmd = [
    &content=     $last[cmd]
    &display=     "! "$last[cmd]
    &filter-text= $last[cmd]
  ]
  bang = [
    &content=     "!"
    &display=     $-plain-bang-insert" !"
    &filter-text= "!"
  ]
  nitems = (count $parts)
  items = [
    (range $nitems |
      each [i]{
        text = $parts[$i]
        if (eq $i (- $nitems 1)) { i = $i"/$" }
        put [
          &content=     $text
          &display=     $i" "$text
          &filter-text= $text
        ]
      }
    )
  ]
  candidates = [$cmd $@items $bang]
  insert-full-cmd = { edit:insert:start; edit:insert-at-dot $last[cmd] }
  insert-part-n = [n]{ edit:insert:start; edit:insert-at-dot $parts[$n] }
  bindings = [
    &!=                   $insert-full-cmd
    &"$"=                 { $insert-part-n -1 }
    &$-plain-bang-insert= $insert-plain-bang~
  ]
  for k $-extra-trigger-keys {
    bindings[$k] = $insert-full-cmd
  }
  range (count $parts) | each [i]{
    bindings[$i] = { $insert-part-n $i }
  }
  edit:-narrow-read {
    put $@candidates
  } [arg]{
    edit:insert-at-dot $arg[content]
    for hook $after-lastcmd { $hook }
  } &modeline="bang-bang " &auto-commit=$true &ignore-case=$true &bindings=$bindings
}

fn bind-trigger-keys [&plain-bang="Alt-!" &extra-triggers=["Alt-1"]]{
  -plain-bang-insert = $plain-bang
  -extra-trigger-keys = $extra-triggers
  edit:insert:binding[!] = $lastcmd~
  for k $extra-triggers {
    edit:insert:binding[$k] = $lastcmd~
  }
  edit:insert:binding[$-plain-bang-insert] = $insert-plain-bang~
}
