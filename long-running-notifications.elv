# [[file:long-running-notifications.org::*Configuration and user-accessible variables][Configuration and user-accessible variables:1]]
  var threshold = 10
# Configuration and user-accessible variables:1 ends here

# [[file:long-running-notifications.org::*Configuration and user-accessible variables][Configuration and user-accessible variables:2]]
  var last-cmd-start-time = 0
  var last-cmd = ""
  var last-cmd-duration = 0
# Configuration and user-accessible variables:2 ends here

# [[file:long-running-notifications.org::*Configuration and user-accessible variables][Configuration and user-accessible variables:3]]
  var notifier = auto
# Configuration and user-accessible variables:3 ends here

# [[file:long-running-notifications.org::*Configuration and user-accessible variables][Configuration and user-accessible variables:4]]
  var notifications-to-try = [ macos libnotify text ]
# Configuration and user-accessible variables:4 ends here

# [[file:long-running-notifications.org::*Configuration and user-accessible variables][Configuration and user-accessible variables:5]]
  var never-notify = [ vi vim emacs nano less more bat ]
  var always-notify = [ ]
# Configuration and user-accessible variables:5 ends here

# [[file:long-running-notifications.org::*Notification mechanisms][Notification mechanisms:1]]
  var notification-fns = [
    &text= [
      &check= { put $true }
      &notify= {|cmd dur start|
        echo (styled "Command lasted "$dur"s" magenta) > /dev/tty
      }
    ]
    &libnotify= [
      &check= { put ?(which notify-send >/dev/null 2>&1) }
      &notify= {|cmd duration start|
        notify-send "Finished: "$cmd "Running time: "$duration"s"
      }
    ]
    &macos= [
      &check= { put ?(which terminal-notifier >/dev/null 2>&1) }
      &notify= {|cmd duration start|
        terminal-notifier -title "Finished: "$cmd -message "Running time: "$duration"s"
      }
    ]
  ]
# Notification mechanisms:1 ends here

# [[file:long-running-notifications.org::*Notification mechanisms][Notification mechanisms:2]]
  fn -choose-notification-fn {
    each {|method-name|
      var method = $notification-fns[$method-name]
      if ($method[check]) {
        put $method[notify]
        return
      }
    } $notifications-to-try
    fail "No valid notification mechanism was found"
  }
# Notification mechanisms:2 ends here

# [[file:long-running-notifications.org::*Notification mechanisms][Notification mechanisms:3]]
  fn -produce-notification {
    if (not-eq (kind-of $notifier) fn) {
      if (eq $notifier auto) {
        set notifier = (-choose-notification-fn)
      } elif (has-key $notification-fns $notifier) {
        set notifier = $notification-fns[$notifier][notify]
      } else {
        fail "Invalid value for $long-running-notifications:notifier: "$notifier", please double check"
      }
    }
    $notifier $last-cmd $last-cmd-duration $last-cmd-start-time
  }
# Notification mechanisms:3 ends here

# [[file:long-running-notifications.org::*Time tracking functions][Time tracking functions:1]]
  fn now {
    put (date +%s)
  }
# Time tracking functions:1 ends here

# [[file:long-running-notifications.org::*Time tracking functions][Time tracking functions:2]]
  fn -last-cmd-in-list {|list|
    var cmd = (take 1 [(edit:wordify $last-cmd) ""])
    has-value $list $cmd
  }
# Time tracking functions:2 ends here

# [[file:long-running-notifications.org::*Time tracking functions][Time tracking functions:3]]
  fn -always-notify { -last-cmd-in-list $always-notify }
  fn -never-notify { -last-cmd-in-list $never-notify }
# Time tracking functions:3 ends here

# [[file:long-running-notifications.org::*Time tracking functions][Time tracking functions:4]]
  fn before-readline-hook {
    var -end-time = (now)
    set last-cmd-duration = (- $-end-time $last-cmd-start-time)
    if (or (-always-notify) (and (not (-never-notify)) (> $last-cmd-duration $threshold))) {
      -produce-notification
    }
  }
# Time tracking functions:4 ends here

# [[file:long-running-notifications.org::*Time tracking functions][Time tracking functions:5]]
  fn after-readline-hook {|cmd|
    set last-cmd = $cmd
    set last-cmd-start-time = (now)
  }
# Time tracking functions:5 ends here

# [[file:long-running-notifications.org::*Initialization][Initialization:1]]
  fn init {
    # Set up the hooks
    use ./prompt-hooks
    prompt-hooks:add-before-readline $before-readline-hook~
    prompt-hooks:add-after-readline $after-readline-hook~
    # Initialize to avoid spurious notification when the module is loaded
    set last-cmd-start-time = (now)
  }
# Initialization:1 ends here

# [[file:long-running-notifications.org::*Initialization][Initialization:2]]
  init
# Initialization:2 ends here
