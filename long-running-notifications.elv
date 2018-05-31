threshold = 10

last-cmd-start-time = 0
last-cmd = ""
last-cmd-duration = 0

notifier = auto

notifications-to-try = [ macos libnotify text ]

notification-fns = [
  &text= [
    &check= { put $true }
    &notify= [cmd dur start]{
      echo (styled "Command lasted "$dur"s" magenta) > /dev/tty
    }
  ]
  &libnotify= [
    &check= { put ?(which notify-send >/dev/null 2>&1) }
    &notify= [cmd duration start]{
      notify-send "Finished: "$cmd "Running time: "$duration"s"
    }
  ]
  &macos= [
    &check= { put ?(which terminal-notifier >/dev/null 2>&1) }
    &notify= [cmd duration start]{
      terminal-notifier -title "Finished: "$cmd -message "Running time: "$duration"s"
    }
  ]
]

fn -choose-notification-fn {
  each [method-name]{
    method = $notification-fns[$method-name]
    if ($method[check]) {
      put $method[notify]
      return
    }
  } $notifications-to-try
  fail "No valid notification mechanism was found"
}

fn -produce-notification {
  if (not-eq (kind-of $notifier) fn) {
    if (eq $notifier auto) {
      notifier = (-choose-notification-fn)
    } elif (has-key $notification-fns $notifier) {
      notifier = $notification-fns[$notifier][notify]
    } else {
      fail "Invalid value for $long-running-notifications:notifier: "$notifier", please double check"
    }
  }
  $notifier $last-cmd $last-cmd-duration $last-cmd-start-time
}

fn now {
  put (date +%s)
}

fn before-readline-hook {
  -end-time = (now)
  last-cmd-duration = (- $-end-time $last-cmd-start-time)
  if (> $last-cmd-duration $threshold) {
    -produce-notification
  }
}

fn after-readline-hook [cmd]{
  last-cmd = $cmd
  last-cmd-start-time = (now)
}

fn init {
  # Set up the hooks
  use ./prompt-hooks
  prompt-hooks:add-before-readline $before-readline-hook~
  prompt-hooks:add-after-readline $after-readline-hook~
  # Initialize to avoid spurious notification when the module is loaded
  last-cmd-start-time = (now)
}

init
