threshold=10

last-cmd-start-time = 0
last-cmd = ""
last-cmd-duration = 0

notifier = auto

notifications-to-try = [ macos text ]

notification-fns = [
  &text= [
    &check= { put $true }
    &notify= [cmd dur start]{
      echo (edit:styled "Command lasted "$dur"s" magenta)
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

fn now {
  put (date +%s)
}

fn before-readline-hook {
  -end-time = (now)
  last-cmd-duration = (- $-end-time $last-cmd-start-time)
  if (> $last-cmd-duration $threshold) {
    $notifier $last-cmd $last-cmd-duration $last-cmd-start-time
  }
}

fn after-readline-hook [cmd]{
  last-cmd = $cmd
  last-cmd-start-time = (now)
}

fn init {
  # First choose the notification mechanism to use
  if (eq $notifier auto) {
    notifier = (-choose-notification-fn)
  } elif (has-key $notification-fns $notifier) {
    notifier = $notification-fns[$notifier]
  } elif (not-eq (kind-of $notifier fn)) {
    fail "Invalid value for $long-running-notifications:notifier: "$notifier", please double check"
  }
  # Then set up the hooks
  use ./prompt-hooks
  prompt-hooks:add-before-readline $before-readline-hook~
  prompt-hooks:add-after-readline $after-readline-hook~
  # Initialize to avoid spurious notification when the module is loaded
  last-cmd-start-time = (now)
}

init
