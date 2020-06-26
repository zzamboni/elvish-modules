fn mk-escape-str [xs]{ put "\e]"(joins ';' $xs)"\a" }

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

fn annotate [&hidden=$false ann]{
if $hidden { cmd AddHiddenAnnotation=$ann } else { cmd AddAnnotation=$ann } }
fn setuservar [var val]{ set SetUserVar $var (print $val | base64) }
fn setbadge [@badge]{ set SetBadgeFormat (print $@badge | base64) }
fn setcolor [key r g b]{ set SetColors $key (printf %02x%02x%02x $r $g $b) }
fn focus { cmd StealFocus }
fn mark { cmd SetMark }
fn profile [p]{ set SetProfile $p }
edit:before-readline = [{ mark } $@edit:before-readline]
fn windowtitle [t]{ print "\e]0;"$t"\a" }
paths = [ $@paths ~/.iterm2 ]
