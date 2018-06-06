fn is [f v]{
  res = ($f)
  if (eq $res $v) {
    echo (styled "OK" green) '(eq ('$f[body]') '(to-string $v)')'
  } else {
    echo (styled "FAIL" red) '('$f[body]')'
    echo "  expected: "(to-string $v)
    echo "    actual: "(to-string $res)
  }
}

fn is-not [f v]{
  res = ($f)
  if (not-eq $res $v) {
    echo (styled "OK" green) '(not-eq ('$f[body]') '(to-string $v)')'
  } else {
    echo (styled "FAIL" red) '('$f[body]')'
    echo "  expected: not "(to-string $v)
    echo "    actual: "(to-string $res)
  }
}

fn set [id @fs]{
  echo (styled "Testing "$id blue)
  each [f]{ $f } $fs
}
