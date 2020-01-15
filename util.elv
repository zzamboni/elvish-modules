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

readline~ = { put (head -n1) }

use builtin
if (has-key $builtin: read-upto~) {
  readline~ = { put (read-upto "\n")[:-1] }
}

fn y-or-n [&style=default prompt]{
  prompt = $prompt" [y/n] "
  if (not-eq $style default) {
    prompt = (styled $prompt $style)
  }
  print $prompt > /dev/tty
  resp = (util:readline)
  eq $resp y
}

fn getfile {
  use re
  print 'Drop a file here: ' >/dev/tty
  re:replace '\\(.)' '$1' (util:readline)[:-1]
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
