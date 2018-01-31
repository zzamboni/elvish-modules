threshold=10

# Automatically-computed variables to keep the last command, its start time and its duration
last_cmd_start_time = 0
last_cmd = ""
last_cmd_duration = 0

# Text-based notification function
# To explicitly set it:
#   long-running-notifications:notifier = $long-running-notifications:text_notifier
text_notifier = { echo (edit:styled "Command lasted "$last_cmd_duration"s" magenta) }

# GUI notifications for macOS. Requires terminal-notifier from https://github.com/julienXX/terminal-notifier
# To explicitly set it:
#   long-running-notifications:notifier = $long-running-notifications:macos_notifier
macos_notifier_extraopts = [ "-sender" "com.apple.Terminal" ]
macos_notifier = { terminal-notifier -title "Finished: "$last_cmd -message "Running time: "$last_cmd_duration"s" $@macos_notifier_extraopts > /dev/null }

# Notification method to use. Defaults to $macos_notifier if terminal-notifier is available, $text_notifier otherwise
notifier = $text_notifier
if ?(which terminal-notifier >/dev/null 2>&1) {
  notifier = $macos_notifier
}

######################################################################
# Functions
######################################################################

# Return the current time in Unix epoch value
fn now {
  put (date +%s)
}

# Check the duration of the last command and produce a
# notification if it exceeds the threshold
fn before_readline_hook {
  _end_time = (now)
  last_cmd_duration = (- $_end_time $last_cmd_start_time)
  if (> $last_cmd_duration $threshold) {
    $notifier
  }
}

# Record the command and its start time
fn after_readline_hook [cmd]{
  last_cmd = $cmd
  last_cmd_start_time = (now)
}

# Set up the prompt hooks to compute times and produce notifications
# as needed
fn setup {
  use ./prompt_hooks
  prompt_hooks:add-before-readline $before_readline_hook~
  prompt_hooks:add-after-readline $after_readline_hook~
  # Initialize to setup time to avoid spurious notification
  last_cmd_start_time = (now)
}
