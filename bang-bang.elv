use ./util
use re
use str

var before-lastcmd = []
var after-lastcmd = []

var -plain-bang-insert = ""

var -extra-trigger-keys = []

fn insert-plain-bang { edit:close-mode; edit:insert-at-dot "!" }

fn lastcmd {
  for hook $before-lastcmd { $hook }
  var last = [(edit:command-history)][-1]
  var parts = [(edit:wordify $last[cmd])]
  var nitems = (count $parts)
  var indicator-width = (util:max (+ 2 (count (to-string $nitems))) (count $-plain-bang-insert))
  var filler = (repeat $indicator-width ' ' | str:join '')
  fn -display-text {|ind text|
    var indcol = $filler$ind
    put $indcol[(- $indicator-width)..]" "$text
  }
  var cmd = [
    &to-accept= $last[cmd]
    &to-show=   (-display-text "!" $last[cmd])
    &to-filter= "! "$last[cmd]
  ]
  var bang = [
    &to-accept= "!"
    &to-show=   (-display-text $-plain-bang-insert "!")
    &to-filter= $-plain-bang-insert" !"
  ]
  var all-args = []
  var arg-text = ""
  if (> $nitems 1) {
    set arg-text = (str:join " " $parts[1..])
    set all-args = [
      &to-accept= $arg-text
      &to-show=   (-display-text "*" $arg-text)
      &to-filter= "* "$arg-text
    ]
  }
  var items = [
    (range $nitems |
      each {|i|
        var text = $parts[$i]
        var ind = (to-string $i)
        if (> $i 9) {
          set ind = ""
        }
        if (eq $i (- $nitems 1)) {
          set ind = $ind" $"
        }
        put [
          &to-accept= $text
          &to-show=   (-display-text $ind $text)
          &to-filter= $ind" "$text
        ]
      }
    )
  ]
  var candidates = [$cmd $@items $all-args $bang]
  fn insert-full-cmd { edit:close-mode; edit:insert-at-dot $last[cmd] }
  fn insert-part {|n| edit:close-mode; edit:insert-at-dot $parts[$n] }
  fn insert-args { edit:close-mode; edit:insert-at-dot $arg-text }
  var bindings = [
    &"!"=                 $insert-full-cmd~
    &"$"=                 { insert-part -1 }
    &$-plain-bang-insert= $insert-plain-bang~
    &"*"=                 $insert-args~
  ]
  for k $-extra-trigger-keys {
    set bindings[$k] = $insert-full-cmd~
  }
  range (util:min (count $parts) 10) | each {|i|
    set bindings[(to-string $i)] = { insert-part $i }
  }
  set bindings = (edit:binding-table $bindings)
  edit:listing:start-custom $candidates &caption="bang-bang " &binding=$bindings &accept={|arg|
    edit:insert-at-dot $arg
    for hook $after-lastcmd { $hook }
  }
}

fn init {|&plain-bang="Alt-!" &extra-triggers=["Alt-1"]|
  set -plain-bang-insert = $plain-bang
  set -extra-trigger-keys = $extra-triggers
  set edit:insert:binding[!] = $lastcmd~
  for k $extra-triggers {
    set edit:insert:binding[$k] = $lastcmd~
  }
  set edit:insert:binding[$-plain-bang-insert] = $insert-plain-bang~
}

init
