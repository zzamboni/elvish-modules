use str

pass-style = green
fail-style = red
info-style = blue

set-indent = '  '

fn status [result text-pass text-fail]{
  if (eq $text-fail '') {
    text-fail = $text-pass
  }
  style = [&$true=$pass-style &$false=$fail-style]
  texts = [&$true=$text-pass  &$false=$text-fail]
  index = (bool $result)
  styled $texts[$index] $style[$index]
}

fn -level-indent [level]{
  repeat $level $set-indent
}

fn -output [@msg &level=0]{
  print (-level-indent $level) >/dev/tty
  echo $@msg >/dev/tty
}

fn check [f @d &check-txt='']{
  msg = (styled (str:join " " [$@d]) $info-style)
  if (eq $check-txt '') {
    check-txt = $f[def]
  }
  put [&top-id='' &level=0]{
    res = (bool ($f))
    -output &level=$level (status $res PASS FAIL) $msg $check-txt
    put $res
  }
}

fn compare [cmp cmpfn f v @d]{
  put [&top-id='' &level=0]{
    res = ($f)
    check-res = ((check { $cmpfn $res $v } $@d &check-txt='('$cmp' ('$f[body]') '(to-string $v)')') &level=$level)
    if (not $check-res) {
      -output &level=$level "  actual: (not ("$cmp' '(to-string $res)' '(to-string $v)'))'
    }
    put $check-res
  }
}

fn is [f v @d]{
  compare eq $eq~ $f $v $@d
}
fn is-not [f v @d]{
  compare not-eq $not-eq~ $f $v $@d
}

fn set [id tests]{
  put [&top-id="" &level=0]{
    if (not-eq $top-id '') {
      id = $top-id' '$id
    }
    -output &level=$level (styled "Testing "$id $info-style)
    -nextlevel = (+ $level 1)
    passed = (each [t]{
        if ($t &top-id=$id &level=$-nextlevel) { put $true }
    } $tests | count)
    res = (eq $passed (count $tests))
    msg = (status $res $passed"/"(count $tests)" passed" '')
    -output &level=$level (styled $id" results:" $info-style) $msg
    put $res
  }
}
