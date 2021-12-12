use str

var pass-style = green
var fail-style = red
var info-style = blue

var set-indent = '  '

fn status {|result text-pass text-fail|
  if (eq $text-fail '') {
    set text-fail = $text-pass
  }
  var style = [&$true=$pass-style &$false=$fail-style]
  var texts = [&$true=$text-pass  &$false=$text-fail]
  var index = (bool $result)
  styled $texts[$index] $style[$index]
}

fn -level-indent {|level|
  repeat $level $set-indent
}

fn -output {|@msg &level=0|
  print (-level-indent $level) >/dev/tty
  echo $@msg >/dev/tty
}

fn check {|f @d &check-txt=''|
  var msg = (styled (str:join " " [$@d]) $info-style)
  if (eq $check-txt '') {
    set check-txt = $f[def]
  }
  put {|&top-id='' &level=0|
    var res = (bool ($f))
    -output &level=$level (status $res PASS FAIL) $msg $check-txt
    put $res
  }
}

fn compare {|cmp cmpfn f v @d|
  put {|&top-id='' &level=0|
    var res = ($f)
    var check-res = ((check { $cmpfn $res $v } $@d &check-txt='('$cmp' ('$f[body]') '(to-string $v)')') &level=$level)
    if (not $check-res) {
      -output &level=$level "  actual: (not ("$cmp' '(to-string $res)' '(to-string $v)'))'
    }
    put $check-res
  }
}

fn is {|f v @d|
  compare eq $eq~ $f $v $@d
}
fn is-not {|f v @d|
  compare not-eq $not-eq~ $f $v $@d
}

fn set {|id tests|
  put {|&top-id="" &level=0|
    if (not-eq $top-id '') {
      set id = $top-id' '$id
    }
    -output &level=$level (styled "Testing "$id $info-style)
    var -nextlevel = (+ $level 1)
    var passed = (each {|t|
        if ($t &top-id=$id &level=$-nextlevel) { put $true }
    } $tests | count)
    var res = (eq $passed (count $tests))
    var msg = (status $res $passed"/"(count $tests)" passed" '')
    -output &level=$level (styled $id" results:" $info-style) $msg
    put $res
  }
}
