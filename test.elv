fn is [f @d]{
  put [&top-id='']{
    msg = ""
    if (> (count $d) 0) {
      msg = (styled (joins " " $d) blue)
    }
    res = ($f)
    if $res {
      echo (styled "OK" green) $msg $f[body]
    } else {
      echo (styled "FAIL" red) $msg $f[body]
      echo "    actual: "(to-string $res)
    }
  }
}

fn set [id @tests]{
  put [&top-id=""]{
    if (not-eq $top-id '') {
      id = $top-id' '$id
    }
    echo (styled "Testing "$id blue)
    each [t]{ $t &top-id=$id } $tests
  }
}
