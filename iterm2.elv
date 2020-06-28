fn mk-escape-str [xs]{ put "\e]"(joins ';' $xs)"\a" }

fn escape-cmd [xs]{
  print (mk-escape-str $xs)
}

fn mk-iterm2-cmd [@x]{ mk-escape-str [1337 $@x] }
fn mk-ftcs-cmd [@x]{ mk-escape-str [133 $@x] }

fn cmd [@x]{ print (mk-iterm2-cmd $@x) }
fn set [@x]{ print (mk-iterm2-cmd (joins '=' $x)) }

fn background-color {
  print (mk-escape-str [4 -2 '?'])
}

fn foreground-color {
  print (mk-escape-str [4 -1 '?'])
}

fn hyperlink [url text &params=[&]]{
  params-str = ""
  if (not-eq $params [&]) {
    params-str = (joins ":" (each [k]{ print $k"="$params[$k] } [(keys $params)]))
  }
  put (mk-escape-str [ '8' $params-str $url ])$text(mk-escape-str [ '8' '' ''])
}

fn mark { cmd SetMark }

fn focus { cmd StealFocus }

fn setdir [d]{
  set CurrentDir $d
}

fn notify [msg]{
  print (mk-escape-str [9 $msg])
}

fn startcopy [&name=""]{
  set CopyToClipboard $name
}

fn endcopy {
  cmd EndCopy
}

fn copystr [s]{
  encoded-str = (print $s | /usr/bin/base64)
  set Copy :$encoded-str
}

fn set-title-color [r g b]{
  escape-cmd [6 1 bg red brightness $r]
  escape-cmd [6 1 bg green brightness $g]
  escape-cmd [6 1 bg blue brightness $b]
}

fn reset-title-color {
  escape-cmd [6 1 bg '*' default]
}

fn annotate [ann &hidden=$false &length=$nil &xy=$nil]{
  parts = [ $ann ]
  if (and $length $xy) {
    parts = [ $ann $length $@xy ]
  } elif (and $length (not $xy)) {
    parts = [ $length $ann ]
  }
  cmd = AddAnnotation
  if $hidden { cmd = AddHiddenAnnotation }
  cmd $cmd=(joins "|" $parts)
}

fn setcolor [key r g b]{
  set SetColors $key (printf %02x%02x%02x $r $g $b)
}

fn profile [p]{ set SetProfile $p }

fn setbackground [@file]{
  encoded-file = ""
  if (not-eq $file []) {
    encoded-file = (print $file[0] | /usr/bin/base64)
  }
  set SetBackgroundImageFile $encoded-file
}

fn setuservar [var val]{
  set SetUserVar $var (print $val | /usr/bin/base64)
}

fn setbadge [@badge]{
  set SetBadgeFormat (print $@badge | /usr/bin/base64)
}

edit:before-readline = [{ mark } $@edit:before-readline]
fn windowtitle [t]{ print "\e]0;"$t"\a" }
paths = [ $@paths ~/.iterm2 ]
