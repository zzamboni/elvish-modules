use str

spinners = (from-json < (path-dir (src)[path])/spinners.json)

default-spinner = 'dots'

-registry = [&]

fn output [@s]{
  print $@s >/dev/tty
}

fn attr [id attr @val]{
  if (has-key $-registry $id) {
    if (eq $val []) {
      put $-registry[$id][$attr]
    } else {
      -registry[$id][$attr] = $val[0]
    }
  } else {
    fail "Nonexisting spinner with ID "$id
  }
}

fn spinner-sleep [s]{
  sleep (to-string (/ (attr $s interval) 1000))
}

fn hide-cursor {
  put "\e[?25l"
}
fn show-cursor {
  put "\e[?25h"
}
fn clear-line {
  put "\e[0K"
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
  -registry[$id] = [
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
  steps = (attr $spinner frames)
  indentation = (str:join '' [(repeat (attr $spinner indent) ' ')])
  pre-string = (if (not-eq (attr $spinner prefix) '') { put (attr $spinner prefix)' ' } else { put '' })
  post-string = (if (not-eq (attr $spinner title) '') { put ' '(attr $spinner title) } else { put '' })
  output $indentation$pre-string(styled $steps[(attr $spinner current)] (all (attr $spinner style)))$post-string(clear-line)"\r"
  inc = 1
  if (eq (kind-of $steps string)) {
    inc = (count $steps[(attr $spinner current)])
  }
  attr $spinner current (% (+ (attr $spinner current) $inc) (count $steps))
}

status-symbols = [
  &success= [ &symbol="✔" &color=green ]
  &error=   [ &symbol="✖" &color=red ]
  &warning= [ &symbol="⚠" &color=yellow ]
  &info=    [ &symbol="ℹ" &color=blue ]
]

fn set-status [spinner status]{
  attr $spinner frames [ $status-symbols[$status][symbol] ]
  attr $spinner style [ $status-symbols[$status][color] ]
  attr $spinner current 0
}

fn run [&spinner=$nil &frames=$nil &interval=$nil &title="" &style=[] &prefix="" &indent=0 &cursor=$false &persist=$false &hide-exception=$false f]{
  s = (new &spinner=$spinner &frames=$frames &interval=$interval &title=$title &style=$style &prefix=$prefix &indent=$indent &cursor=$cursor &persist=$persist &hide-exception=$hide-exception)
  stop = $false
  status = $nil
  run-parallel {
    if (not (attr $s cursor)) { output (hide-cursor) }
    while (not $stop) {
      step $s
      spinner-sleep $s
    }
    if $persist {
      if (eq $persist status) {
        if $status {
          set-status $s success
        } else {
          set-status $s error
        }
      } elif (eq (kind-of $persist) string) {
        set-status $s $persist
      }
      step $s
      output "\n"
    } else {
      output (clear-line)
    }
    if (not (attr $s cursor)) { output (show-cursor) }
    if (and (not $status) (not $hide-exception)) {
      show $status
    }
  } {
    try {
      $f
    } except e {
      status = $e
    } else {
      status = $ok
    } finally {
      stop = $true
    }
  }
}

fn demo [&time=2 &style=blue &persist=$false]{
  list | each [s]{
    run &spinner=$s &title=$s &style=$style &persist=$persist { sleep $time }
  }
}
