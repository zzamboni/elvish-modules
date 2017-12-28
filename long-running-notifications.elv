# Produce notifications for long-running commands
# Diego Zamboni <diego@zzamboni.org>

# To use it:
#     use long-running-notifications
#     long-running-notifications:setup
#
# Needs the prompt_hooks package from https://github.com/zzamboni/vcsh_elvish/blob/master/.elvish/lib/
#
# Tries to determine the best notification method to use based on available commands. The
# method can be specified manually by assigning a lambda to `$long-running-notifications:notifier`.
#
# Built-in notifiers:
#
# - `$long-running-notifications:macos_notifier` (GUI notifications on macOS, used if
#   `terminal-notifier` is available)
# - `$long-running-notifications:text_notifier` (used if nothing else works)
#
# You can provide your own notification function. It can make use of the following variables:
# `$long-running-notifications:last_cmd`, `$long-running-notifications:last_cmd_duration`
# and `$long-running-notifications:last_cmd_duration`. For example:
#
#     long-running-notifications:notifier = { echo "LONG COMMAND! Lasted "$long-running-notifications:last_cmd_duration }
#
# The threshold for the notifications is 10 seconds by default, can be changed by
# assigning a value to the `long-running-notifications:threshold` variable.

######################################################################
# Configuration variables
######################################################################

# Threshold in seconds for producing notifications (default 10)
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
  use github.com/zzamboni/modules.elv/prompt_hooks
  prompt_hooks:add-before-readline $before_readline_hook~
  prompt_hooks:add-after-readline $after_readline_hook~
  # Initialize to setup time to avoid spurious notification
  last_cmd_start_time = (now)
}
