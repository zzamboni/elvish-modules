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

fn y-or-n [&style=default prompt]{
  prompt = $prompt" [y/n] "
  if (not-eq $style default) {
    prompt = (styled $prompt $style)
  }
  print $prompt > /dev/tty
  resp = (head -n1 < /dev/tty)
  eq $resp y
}

fn getfile {
  use re
  print 'Drop a file here: ' >/dev/tty
  re:replace '\\(.)' '$1' (head -n 1 </dev/tty)[:-1]
}

fn max [a @rest]{
  res = $a
  each [n]{ if (> $n $res) { res = $n } } $rest
  put $res
}

fn min [a @rest]{
  res = $a
  each [n]{ if (< $n $res) { res = $n } } $rest
  put $res
}

fn cond [clauses]{
  range &step=2 (count $clauses) | each [i]{
    exp = $clauses[$i]
    if (eq (kind-of $exp) fn) { exp = ($exp) }
    if $exp {
      val = $clauses[(+ $i 1)]
      if (eq (kind-of $val) fn) {
       $val
     } else {
       put $val
     }
     return
    }
  }
}
