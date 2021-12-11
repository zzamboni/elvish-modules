use str
use path
use github.com/zzamboni/elvish-modules/tty

var spinners = (from-json < (path:dir (src)[name])/spinners.json)

var default-spinner = 'dots'

var -sr = [&]

fn -output {|@s|
  print $@s >/dev/tty
}

fn new {|&spinner=$nil &frames=$nil &interval=$nil &title="" &style=[] &prefix="" &indent=0 &cursor=$false &persist=$false &hide-exception=$false &id=$nil|
  # Determine ID to use
  set id = (or $id (var e = ?(uuidgen)) (randint 0 9999999))
  # Use default spinner if none is specified
  if (not $spinner) { set spinner = $default-spinner }
  # Automatically convert non-list styles, so you can do e.g. &style=red
  if (not-eq (kind-of $style) list) { set style = [$style] }
  # Create and store the new spinner object
  set -sr[$id] = [
    &id=             $id
    &spinner=        $spinner
    &frames=         (or $frames $spinners[$spinner][frames])
    &interval=       (or $interval $spinners[$spinner][interval])
    &title=          $title
    &prefix=         $prefix
    &indent=         $indent
    &style=          $style
    &cursor=         $cursor
    &persist=        $persist
    &hide-exception= $hide-exception
    &current=        0
    &status=         $ok
    &stop=           $false
  ]
  # Return ID of the new spinner
  put $id
}

fn step {|spinner|
  var steps = $-sr[$spinner][frames]
  var indentation = (str:join '' [(repeat $-sr[$spinner][indent] ' ')])
  var pre-string = (if (not-eq $-sr[$spinner][prefix] '') { put $-sr[$spinner][prefix]' ' } else { put '' })
  var post-string = (if (not-eq $-sr[$spinner][title] '') { put ' '$-sr[$spinner][title] } else { put '' })
  tty:set-cursor-pos (all $-sr[$spinner][initial-pos])
  -output $indentation$pre-string(styled $steps[$-sr[$spinner][current]] (all $-sr[$spinner][style]))$post-string
  tty:clear-line
  var inc = 1
  if (eq (kind-of $steps string)) {
    set inc = (count $steps[$-sr[$spinner][current]])
  }
  set -sr[$spinner][current] = (% (+ $-sr[$spinner][current] $inc) (count $steps))
}

var persist-symbols = [
  &success= [ &symbol="✔" &color=green ]
  &error=   [ &symbol="✖" &color=red ]
  &warning= [ &symbol="⚠" &color=yellow ]
  &info=    [ &symbol="ℹ" &color=blue ]
]

fn set-symbol {|spinner symbol|
  set -sr[$spinner][frames] = [ $persist-symbols[$symbol][symbol] ]
  set -sr[$spinner][style] = [ $persist-symbols[$symbol][color] ]
  set -sr[$spinner][current] = 0
}

fn spinner-sleep {|s|
  sleep (to-string (/ $-sr[$s][interval] 1000))
}

fn persist {|spinner|
  if (eq $-sr[$spinner][persist] status) {
    if $-sr[$spinner][status] {
      set-symbol $spinner success
    } else {
      set-symbol $spinner error
    }
  } elif (eq (kind-of $-sr[$spinner][persist]) string) {
    set-symbol $spinner $-sr[$spinner][persist]
  }
  step $spinner
  -output "\n"
  set -sr[$spinner][initial-pos] = [(tty:cursor-pos)]
}

fn attr {|id attr @val|
  if (has-key $-sr $id) {
    if (eq $val []) {
      put $-sr[$id][$attr]
    } else {
      if (eq $attr spinner) {
        # Automatically populate frames and interval based on spinner
        var name = $val[0]
        set -sr[$id][spinner]  = $name
        set -sr[$id][frames]   = $spinners[$name][frames]
        set -sr[$id][interval] = $spinners[$name][interval]
        set -sr[$id][current]  = 0
      } elif (eq $attr style) {
        # Automatically convert non-list styles, so you can do e.g. &style=red
        var style = $val[0]
        if (not-eq (kind-of $style) list) { set style = [$style] }
        set -sr[$id][style] = $style
      } else {
        set -sr[$id][$attr] = $val[0]
      }
    }
  } else {
    fail "Nonexisting spinner with ID "$id
  }
}

fn do-spinner {|spinner|
  if (not $-sr[$spinner][cursor]) {
    tty:hide-cursor
  }
  set -sr[$spinner][initial-pos] = [(tty:cursor-pos)]
  while (not $-sr[$spinner][stop]) {
    step $spinner
    spinner-sleep $spinner
    if (has-key $-sr[$spinner] next-spinner-id) {
      var next-spinner-id = $-sr[$spinner][next-spinner-id]
      # Indicator to persist the current spinner and continue with a new definition
      persist $spinner
      set -sr[$spinner] = $-sr[$next-spinner-id]
      set -sr[$spinner][id] = $spinner
      set -sr[$spinner][initial-pos] = [(tty:cursor-pos)]
      del -sr[$next-spinner-id]
    }
  }
  if $-sr[$spinner][persist] {
    persist $spinner
  } else {
    tty:set-cursor-pos (all $-sr[$spinner][initial-pos])
    tty:clear-line
  }
  if (not $-sr[$spinner][cursor]) { tty:show-cursor }
  if (and (not $-sr[$spinner][status]) (not $-sr[$spinner][hide-exception])) {
    show $-sr[$spinner][status]
  }
  del -sr[$spinner]
}

fn start {|spinner|
  do-spinner $spinner &
}

fn stop {|spinner &status=$ok|
  set -sr[$spinner][status] = $status
  set -sr[$spinner][stop] = $true
}

fn run {|&spinner=$nil &frames=$nil &interval=$nil &title="" &style=[] &prefix="" &indent=0 &cursor=$false &persist=$false &hide-exception=$false f|
  # Create spinner
  var s = (new &spinner=$spinner &frames=$frames &interval=$interval &title=$title &style=$style &prefix=$prefix &indent=$indent &cursor=$cursor &persist=$persist &hide-exception=$hide-exception)
  # Determine whether to pass the spinner ID to the function
  var f-args = [$s]
  if (eq $f[arg-names] []) { set f-args = [] }
  # Run spinner in parallel with the function
  var status = $ok
  run-parallel {
    do-spinner $s
  } {
    set status = $ok
    try {
      $f $@f-args
    } except e {
      set status = $e
    } finally {
      # Short pause to avoid a potential race condition when the
      # function finishes too quickly
      sleep 0.05
      stop &status=$status $s
    }
  }
}

fn persist-and-new {|old-spinner &spinner=$nil &frames=$nil &interval=$nil &title="" &style=[] &prefix="" &indent=0 &cursor=$false &persist=$false &hide-exception=$false|
  var new-spinner = (new &spinner=$spinner &frames=$frames &interval=$interval &title=$title &style=$style &prefix=$prefix &indent=$indent &cursor=$cursor &persist=$persist &hide-exception=$hide-exception)
  set -sr[$old-spinner][next-spinner-id] = $new-spinner
}

fn list {
  keys $spinners | order
}

fn demo {|&time=2 &style=blue &persist=$false|
  list | each {|s|
    run &spinner=$s &title=$s &style=$style &persist=$persist { sleep $time }
  }
}
