use re

fn dotify_string [str dotify_length]{
  if (or (== $dotify_length 0) (<= (count $str) $dotify_length)) {
    put $str
  } else {
    re:replace '(.{'$dotify_length'}).*' '$1…' $str
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
