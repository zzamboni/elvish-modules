fn dotify-string [str dotify-length]{
  if (or (<= $dotify-length 0) (<= (count $str) $dotify-length)) {
    put $str
  } else {
    put $str[:$dotify-length]'…'
  }
}

fn pipesplit [l1 l2 l3]{
  pout = (pipe)
  perr = (pipe)
  run-parallel {
    $l1 > $pout 2> $perr
    pwclose $pout
    pwclose $perr
  } {
    $l2 < $pout
    prclose $pout
  } {
    $l3 < $perr
    prclose $perr
  }
}

fn eval [str]{
  tmpf = (mktemp)
  echo $str > $tmpf
  -source $tmpf
  rm -f $tmpf
}

-read-upto-eol~ = [eol]{ put (head -n1) }

use builtin
if (has-key $builtin: read-upto~) {
  -read-upto-eol~ = [eol]{ read-upto $eol }
}

fn readline [&eol="\n" &nostrip=$false &prompt=$nil]{
  if $prompt {
    print $prompt > /dev/tty
  }
  local:line = (if $prompt {
      -read-upto-eol $eol < /dev/tty
    } else {
      -read-upto-eol $eol
  })
  if (and (not $nostrip) (!=s $line '') (==s $line[-1:] $eol)) {
    put $line[:-1]
  } else {
    put $line
  }
}

fn y-or-n [&style=default prompt]{
  prompt = $prompt" [y/n] "
  if (not-eq $style default) {
    prompt = (styled $prompt $style)
  }
  print $prompt > /dev/tty
  resp = (readline)
  eq $resp y
}

fn getfile {
  use re
  print 'Drop a file here: ' >/dev/tty
  re:replace '\\(.)' '$1' (readline)[:-1]
}

fn max [a @rest &with=[v]{put $v}]{
  res = $a
  val = ($with $a)
  each [n]{
    nval = ($with $n)
    if (> $nval $val) {
      res = $n
      val = $nval
    }
  } $rest
  put $res
}

fn min [a @rest &with=[v]{put $v}]{
  res = $a
  val = ($with $a)
  each [n]{
    nval = ($with $n)
    if (< $nval $val) {
      res = $n
      val = $nval
    }
  } $rest
  put $res
}

fn cond [clauses]{
  range &step=2 (count $clauses) | each [i]{
    exp = $clauses[$i]
    if (eq (kind-of $exp) fn) { exp = ($exp) }
    if $exp {
      put $clauses[(+ $i 1)]
      return
    }
  }
}

fn optional-input [@input]{
  if (eq $input []) {
    input = [(all)]
  } elif (eq (count $input) 1) {
    input = [ (explode $input[0]) ]
  } else {
    fail "util:optional-input: want 0 or 1 arguments, got "(count $input)
  }
  put $input
}

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
    while (not ?(char1=$edit:current-command[$i])) { i = (- $i 1) }
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

fn select [p @input]{
  each [i]{ if ($p $i) { put $i} } (optional-input $@input)
}

fn remove [p @input]{
  each [i]{ if (not ($p $i)) { put $i} } (optional-input $@input)
}

fn partial [f @p-args]{
  put [@args]{
    $f $@p-args $@args
  }
}

use str

fn fix-deprecated [f]{
  deprecated = [
    &all= all
    &str:join= str:join
    &str:split= str:split
    &str:replace= str:replace
  ]
  sed-cmd = (str:join "; " [(keys $deprecated | each [d]{ put "s/"$d"/"$deprecated[$d]"/" })])
  sed -i '' -e $sed-cmd $f
}
