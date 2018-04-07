use re
use builtin
use ./util

fn -signed-compare [ltfn v1 v2]{
  if     ($ltfn $v1 $v2) { put  1
  } elif ($ltfn $v2 $v1) { put -1
  } else                 { put  0 }
}

fn -num-str-cmp [e1 e2]{
  lt = $<s~
  if (re:match '^\d+$' $e1$e2) { lt = $<~ }
  -signed-compare $lt $e1 $e2
}

fn -part-compare [v1 v2]{
  v1s = [(splits '.' $v1)]
  v2s = [(splits '.' $v2)]
  num = (util:max (count $v1s) (count $v2s))
  fill = [(repeat $num 0)]
  range $num | each [i]{
    comp = (-num-str-cmp [$@v1s $@fill][$i] [$@v2s $@fill][$i])
    if (!= $comp 0) {
      put $comp
      return
    }
  }
  put 0
}

fn cmp [v1 v2]{
  rel1 prerel1 @_ = (splits '-' $v1) $false
  rel2 prerel2 @_ = (splits '-' $v2) $false
  comp = (-part-compare $rel1 $rel2)
  if (!= $comp 0) {
    put $comp
  } else {
    if (and $prerel1 $prerel2) {
      -part-compare $prerel1 $prerel2
    } else {
      -signed-compare [v1 v2]{ and $v1 (not $v2) } $prerel1 $prerel2
    }
  }
}

fn -seq-compare [op expected @vers]{
  res = $true
  last = $false
  each [v]{
    if $last {
      res = (and $res ($op (cmp $last $v) $expected))
    }
    last = $v
  } $vers
  put $res
}

fn '<' [@vers]{
  -seq-compare $builtin:eq~ 1 $@vers
}

fn '>' [@vers]{
  -seq-compare $builtin:eq~ -1 $@vers
}

fn eq [@vers]{
  -seq-compare $builtin:eq~ 0 $@vers
}

fn not-eq [@vers]{
  -seq-compare $builtin:not-eq~ 0 $@vers
}

fn '<=' [@vers]{
  -seq-compare $builtin:not-eq~ -1 $@vers
}

fn '>=' [@vers]{
  -seq-compare $builtin:not-eq~ 1 $@vers
}
