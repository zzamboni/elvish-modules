var env-vars = [&]

var always-vars = [&]

fn add-var {|var lambda &always=$false|
  set env-vars[$var] = $lambda
  set always-vars[$var] = $always
}

fn eval-var {|var &always=$false|
  if (has-key $env-vars $var) {
    if (or $always (not (has-env $var)) $always-vars[$var]) {
      set-env $var ($env-vars[$var])
    }
  } else {
    echo (styled "lazy-vars: Variable "$var" is not defined" red)
  }
}

var orig-cmd = [&]

fn add-alias {|cmd vars &always-eval=$false|
  set orig-cmd[$cmd] = (eval "put "(resolve $cmd))
  edit:add-var $cmd"~" {|@_args|
    each {|v|
      eval-var &always=$always-eval $v
    } $vars
    $orig-cmd[$cmd] $@_args
    if (not $always-eval) {
      edit:add-var $cmd"~" $orig-cmd[$cmd]
    }
  }
}
