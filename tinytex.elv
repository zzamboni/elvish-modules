use re

fn install-by-file [f]{
  search-res = [(tlmgr search --global --file "/"$f )]
  pkgs = [(each [l]{ if (eq $l[-1] ":") { put $l[0:-1] } } $search-res)]
  if (> (count $pkgs) 1) {
    i = 0
    echo (styled "There are multiple packages which contain a matching file:" blue)
    each [l]{
      if (eq $l[-1] ":") {
        echo (styled $i") "$l yellow)
        i = (+ $i 1)
      } else {
        echo $l
      }
    } $search-res
    print (styled "Please enter the numbers of the packages to install (comma-or-space-separated, empty to cancel): " blue)
    resp = (read-upto "\n")[0:-1]
    pkgs = [(re:split "[, ]+" $resp | each [n]{ if (not-eq $n '') { put $pkgs[$n] } })]
    if (> (count $pkgs) 0) {
      echo (styled "Packages selected: "(joins ", " $pkgs) yellow)
    }
  }
  each [pkg]{
    echo (styled "Installing package "$pkg blue)
    tlmgr install $pkg
  } $pkgs
}
