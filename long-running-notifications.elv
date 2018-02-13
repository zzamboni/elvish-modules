threshold=10

last_cmd_start_time = 0
last_cmd = ""
last_cmd_duration = 0

notifier = auto

notifications-to-try = [ macos text ]

notification_fns = [
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
  each [method_name]{
    method = $notification_fns[$method_name]
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

fn before_readline_hook {
  _end_time = (now)
  last_cmd_duration = (- $_end_time $last_cmd_start_time)
  if (> $last_cmd_duration $threshold) {
    $notifier $last_cmd $last_cmd_duration $last_cmd_start_time
  }
}

fn after_readline_hook [cmd]{
  last_cmd = $cmd
  last_cmd_start_time = (now)
}

fn init {
  # First choose the notification mechanism to use
  if (eq $notifier auto) {
    notifier = (-choose-notification-fn)
  } elif (has-key $notification_fns $notifier) {
    notifier = $notification_fns[$notifier]
  } elif (not-eq (kind-of $notifier fn)) {
    fail "Invalid value for $long-running-notifications:notifier: "$notifier", please double check"
  }
  # Then set up the hooks
  use ./prompt_hooks
  prompt_hooks:add-before-readline $before_readline_hook~
  prompt_hooks:add-after-readline $after_readline_hook~
  # Initialize to avoid spurious notification when the module is loaded
  last_cmd_start_time = (now)
}

init
