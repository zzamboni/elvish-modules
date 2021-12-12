use str
use path

fn mk-escape-str {|xs| put "\e]"(str:join ';' $xs)"\a" }

fn escape-cmd {|xs|
  print (mk-escape-str $xs)
}

fn mk-iterm2-cmd {|@x| mk-escape-str [1337 $@x] }
fn mk-ftcs-cmd {|@x| mk-escape-str [133 $@x] }

fn cmd {|@x| print (mk-iterm2-cmd $@x) }
fn set-var {|@x| print (mk-iterm2-cmd (str:join '=' $x)) }
fn ftcs-cmd {|@x| print (mk-ftcs-cmd $@x) }

fn set-title-color {|r g b|
  escape-cmd [6 1 bg red brightness $r]
  escape-cmd [6 1 bg green brightness $g]
  escape-cmd [6 1 bg blue brightness $b]
}

fn reset-title-color {
  escape-cmd [6 1 bg '*' default]
}

fn setcolor {|key r g b|
  set-var SetColors $key (printf %02x%02x%02x $r $g $b)
}

fn report-background-color {
  print (mk-escape-str [4 -2 '?'])
}

fn report-foreground-color {
  print (mk-escape-str [4 -1 '?'])
}

fn setbackground {|@file|
  var encoded-file = ""
  if (not-eq $file []) {
    set encoded-file = (print $file[0] | /usr/bin/base64)
  }
  set-var SetBackgroundImageFile $encoded-file
}

fn hyperlink {|url text &params=[&]|
  var params-str = ""
  if (not-eq $params [&]) {
    set params-str = (str:join ":" (each {|k| print $k"="$params[$k] } [(keys $params)]))
  }
  put (mk-escape-str [ '8' $params-str $url ])$text(mk-escape-str [ '8' '' ''])
}

fn mark { cmd SetMark }

fn focus { cmd StealFocus }

fn setdir {|d|
  set-var CurrentDir $d
}

fn notify {|msg|
  print (mk-escape-str [9 $msg])
}

fn startcopy {|&name=""|
  set-var CopyToClipboard $name
}

fn endcopy {
  cmd EndCopy
}

fn copystr {|s|
  var encoded-str = (print $s | /usr/bin/base64)
  set-var Copy :$encoded-str
}

fn annotate {|ann &hidden=$false &length=$nil &xy=$nil|
  var parts = [ $ann ]
  if (and $length $xy) {
    set parts = [ $ann $length $@xy ]
  } elif (and $length (not $xy)) {
    set parts = [ $length $ann ]
  }
  var cmd = AddAnnotation
  if $hidden { set cmd = AddHiddenAnnotation }
  cmd $cmd=(str:join "|" $parts)
}

fn profile {|p| set-var SetProfile $p }

fn setuservar {|var val|
  set-var SetUserVar $var (print $val | /usr/bin/base64)
}
fn reportvar {|var|
  set-var ReportVariable (print $var | /usr/bin/base64)
}

fn setbadge {|@badge|
  set-var SetBadgeFormat (print $@badge | /usr/bin/base64)
}

fn set-remotehost {|user host|
  set-var RemoteHost $user"@"$host
}

fn set-currentdir {|dir|
  set-var CurrentDir $dir
}

fn windowtitle {|t| print "\e]0;"$t"\a" }

fn ftcs-prompt { ftcs-cmd A }
fn ftcs-command-start { ftcs-cmd B }
fn ftcs-command-executed {|cmd| ftcs-cmd C }
fn ftcs-command-finished {|&status=0| ftcs-cmd D $status }

use platform

var original-prompt-fn = $nil

fn init {
  # Save the original prompt
  set original-prompt-fn = $edit:prompt
  # Define a new prompt function which calls the original one and
  # additionally emits the necessary escape codes at the end.
  set edit:prompt = {
    $original-prompt-fn
    set-currentdir $pwd >/dev/tty
    ftcs-command-start >/dev/tty
  }
  # Emit end-of-command and start-of-prompt markers before displaying
  # each new prompt line, and set current host/user/dir.
  set edit:before-readline = [
    {
      ftcs-command-finished
      set-remotehost $E:USER (platform:hostname)
      ftcs-prompt
    }
    $@edit:before-readline
  ]
  # Emit start-of-command-output marker after the user presses Enter
  # on the command line.
  set edit:after-readline = [
    $ftcs-command-executed~
    $@edit:after-readline
  ]
}

fn clear-screen {
  edit:clear
  ftcs-prompt > /dev/tty
}

if (path:is-dir ~/.iterm2) {
  set paths = [ $@paths ~/.iterm2 ]
}
