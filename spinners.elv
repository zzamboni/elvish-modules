use str
use github.com/zzamboni/elvish-modules/tty

spinners = (from-json < (path-dir (src)[path])/spinners.json)

default-spinner = 'dots'

-sr = [&]

fn output [@s]{
  print $@s >/dev/tty
}

fn list {
  keys $spinners | order
}

fn new [&spinner=$nil &frames=$nil &interval=$nil &title="" &style=[] &prefix="" &indent=0 &cursor=$false &persist=$false &hide-exception=$false &id=$nil]{
  # Determine ID to use
  id = (or $id (e=?(uuidgen)) (randint 0 9999999))
  # Use default spinner if none is specified
  if (not $spinner) { spinner = $default-spinner }
  # Automatically convert non-list styles, so you can do e.g. &style=red
  if (not-eq (kind-of $style) list) { style = [$style] }
  # Create and store the new spinner object
  -sr[$id] = [
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
  ]
  # Return ID of the new spinner
  put $id
}

fn step [spinner]{
  steps = $-sr[$spinner][frames]
  indentation = (str:join '' [(repeat $-sr[$spinner][indent] ' ')])
  pre-string = (if (not-eq $-sr[$spinner][prefix] '') { put $-sr[$spinner][prefix]' ' } else { put '' })
  post-string = (if (not-eq $-sr[$spinner][title] '') { put ' '$-sr[$spinner][title] } else { put '' })
  tty:set-cursor-pos (all $-sr[$spinner][initial-pos])
  output $indentation$pre-string(styled $steps[$-sr[$spinner][current]] (all $-sr[$spinner][style]))$post-string
  tty:clear-line
  inc = 1
  if (eq (kind-of $steps string)) {
    inc = (count $steps[$-sr[$spinner][current]])
  }
  -sr[$spinner][current] = (% (+ $-sr[$spinner][current] $inc) (count $steps))
}

persist-symbols = [
  &success= [ &symbol="✔" &color=green ]
  &error=   [ &symbol="✖" &color=red ]
  &warning= [ &symbol="⚠" &color=yellow ]
  &info=    [ &symbol="ℹ" &color=blue ]
]

fn set-symbol [spinner symbol]{
  -sr[$spinner][frames] = [ $persist-symbols[$symbol][symbol] ]
  -sr[$spinner][style] = [ $persist-symbols[$symbol][color] ]
  -sr[$spinner][current] = 0
}

fn spinner-sleep [s]{
  sleep (to-string (/ $-sr[$s][interval] 1000))
}

fn attr [id attr @val]{
  if (has-key $-sr $id) {
    if (eq $val []) {
      put $-sr[$id][$attr]
    } else {
      if (eq $attr spinner) {
        # Automatically populate frames and interval based on spinner
        name = $val[0]
        -sr[$id][spinner]  = $name
        -sr[$id][frames]   = $spinners[$name][frames]
        -sr[$id][interval] = $spinners[$name][interval]
        -sr[$id][current]  = 0
      } elif (eq $attr style) {
        # Automatically convert non-list styles, so you can do e.g. &style=red
        style = $val[0]
        if (not-eq (kind-of $style) list) { style = [$style] }
        -sr[$id][style] = $style
      } else {
        -sr[$id][$attr] = $val[0]
      }
    }
  } else {
    fail "Nonexisting spinner with ID "$id
  }
}

fn do-spinner [spinner]{
  -sr[$spinner][stop] = $false
  -sr[$spinner][status] = $ok
  if (not $-sr[$spinner][cursor]) {
    tty:hide-cursor
  }
  -sr[$spinner][initial-pos] = [(tty:cursor-pos)]
  while (not $-sr[$spinner][stop]) {
    step $spinner
    spinner-sleep $spinner
  }
  if $-sr[$spinner][persist] {
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
    output "\n"
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

fn start [spinner]{
  do-spinner $spinner &
}

fn stop [spinner &status=$ok]{
  -sr[$spinner][status] = $status
  -sr[$spinner][stop] = $true
}

fn run [&spinner=$nil &frames=$nil &interval=$nil &title="" &style=[] &prefix="" &indent=0 &cursor=$false &persist=$false &hide-exception=$false f]{
  # Create spinner
  s = (new &spinner=$spinner &frames=$frames &interval=$interval &title=$title &style=$style &prefix=$prefix &indent=$indent &cursor=$cursor &persist=$persist &hide-exception=$hide-exception)
  # Determine whether to pass the spinner ID to the function
  f-args = [$s]
  if (eq $f[arg-names] []) { f-args = [] }
  # Run spinner in parallel with the function
  run-parallel {
    do-spinner $s
  } {
    status = $ok
    try {
      $f $@f-args
    } except e {
      status = $e
    } else {
      status = $ok
    } finally {
      stop &status=$status $s
    }
  }
}

fn demo [&time=2 &style=blue &persist=$false]{
  list | each [s]{
    run &spinner=$s &title=$s &style=$style &persist=$persist { sleep $time }
  }
}
