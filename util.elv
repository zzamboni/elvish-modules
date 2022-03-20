fn dotify-string {|str dotify-length|
  if (or (<= $dotify-length 0) (<= (count $str) $dotify-length)) {
    put $str
  } else {
    put $str[..$dotify-length]'…'
  }
}

use file

fn pipesplit {|l1 l2 l3|
  var pout = (file:pipe)
  var perr = (file:pipe)
  run-parallel {
    $l1 > $pout 2> $perr
    file:close $pout[w]
    file:close $perr[w]
  } {
    $l2 < $pout
    file:close $pout[r]
  } {
    $l3 < $perr
    file:close $perr[r]
  }
}

var -read-upto-eol~ = {|eol| put (head -n1) }

use builtin
if (has-key $builtin: read-upto~) {
  set -read-upto-eol~ = {|eol| read-upto $eol }
}

fn readline {|&eol="\n" &nostrip=$false &prompt=$nil|
  if $prompt {
    print $prompt > /dev/tty
  }
  var line = (if $prompt {
      -read-upto-eol $eol < /dev/tty
    } else {
      -read-upto-eol $eol
  })
  if (and (not $nostrip) (!=s $line '') (==s $line[-1..] $eol)) {
    put $line[..-1]
  } else {
    put $line
  }
}

fn y-or-n {|&style=default prompt|
  set prompt = $prompt" [y/n] "
  if (not-eq $style default) {
    set prompt = (styled $prompt $style)
  }
  print $prompt > /dev/tty
  var resp = (readline)
  eq $resp y
}

fn getfile {
  use re
  print 'Drop a file here: ' >/dev/tty
  var fname = (read-line)
  each {|p|
    set fname = (re:replace $p[0] $p[1] $fname)
  } [['\\(.)' '$1'] ['^''' ''] ['\s*$' ''] ['''$' '']]
  put $fname
}

fn max {|a @rest &with={|v|put $v}|
  var res = $a
  var val = ($with $a)
  each {|n|
    var nval = ($with $n)
    if (> $nval $val) {
      set res = $n
      set val = $nval
    }
  } $rest
  put $res
}

fn min {|a @rest &with={|v|put $v}|
  var res = $a
  var val = ($with $a)
  each {|n|
    var nval = ($with $n)
    if (< $nval $val) {
      set res = $n
      set val = $nval
    }
  } $rest
  put $res
}

fn cond {|clauses|
  range &step=2 (count $clauses) | each {|i|
    var exp = $clauses[$i]
    if (eq (kind-of $exp) fn) { set exp = ($exp) }
    if $exp {
      put $clauses[(+ $i 1)]
      return
    }
  }
}

fn optional-input {|@input|
  if (eq $input []) {
    set input = [(all)]
  } elif (== (count $input) 1) {
    set input = [ (all $input[0]) ]
  } else {
    fail "util:optional-input: want 0 or 1 arguments, got "(count $input)
  }
  put $input
}

fn select {|p @input|
  each {|i| if ($p $i) { put $i} } (optional-input $@input)
}

fn remove {|p @input|
  each {|i| if (not ($p $i)) { put $i} } (optional-input $@input)
}

fn partial {|f @p-args|
  put {|@args|
    $f $@p-args $@args
  }
}

fn path-in {|obj path &default=$nil|
  each {|k|
    try {
      set obj = $obj[$k]
    } catch {
      set obj = $default
      break
    }
  } $path
  put $obj
}

use str

fn fix-deprecated {|f|
  var deprecated = [
    &all= all
    &str:join= str:join
    &str:split= str:split
    &str:replace= str:replace
  ]
  var sed-cmd = (str:join "; " [(keys $deprecated | each {|d| put "s/"$d"/"$deprecated[$d]"/" })])
  sed -i '' -e $sed-cmd $f
}
