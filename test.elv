fn is [f v @d]{
  res = ($f)
  msg = ""
  if (> (count $d) 0) {
    msg = (styled (joins " " $d) blue)
  }
  if (eq $res $v) {
    echo (styled "OK" green) $msg '(eq ('$f[body]') '(to-string $v)')'
  } else {
    echo (styled "FAIL" red) $msg '('$f[body]')'
    echo "  expected: "(to-string $v)
    echo "    actual: "(to-string $res)
  }
}

fn is-not [f v @d]{
  res = ($f)
  msg = ""
  if (> (count $d) 0) {
    msg = (styled (joins " " $d) blue)
  }
  if (not-eq $res $v) {
    echo (styled "OK" green) $msg '(not-eq ('$f[body]') '(to-string $v)')'
  } else {
    echo (styled "FAIL" red) $msg '('$f[body]')'
    echo "  expected: not "(to-string $v)
    echo "    actual: "(to-string $res)
  }
}

fn set [id @fs]{
  echo (styled "Testing "$id blue)
  each [f]{ $f } $fs
}
