use re
use str
use builtin
use ./util

fn -signed-compare {|ltfn v1 v2|
  util:cond [
    { $ltfn $v1 $v2 }  1
    { $ltfn $v2 $v1 } -1
    :else              0
  ]
}

fn -part-compare {|v1 v2|
  each {|k|
    var comp = (-signed-compare $'<~' $v1[$k] $v2[$k])
    if (!= $comp 0) {
      put $comp
      return
    }
  } [major minor patch]
  put 0
}

var semver-regex = '^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'
var semver-regex-nonstrict = '^[vV]?(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'

var allow-v-default = $false

fn get-regex {|&allow-v=$nil|
  set allow-v = (if (not-eq $allow-v $nil) { put $allow-v } else { put $allow-v-default })
  if $allow-v {
    put $semver-regex-nonstrict
  } else {
    put $semver-regex
  }
}

fn validate {|string &allow-v=$nil|
  if (not (re:match (get-regex &allow-v=$allow-v) $string)) {
    fail "Invalid SemVer string: "$string
  }
}

fn parse {|string &allow-v=$nil|
  if (validate $string &allow-v=$allow-v) {
    var parts = (re:find (get-regex &allow-v=$allow-v) $string)[groups]
    put [
      &major=  $parts[1][text]
      &minor=  $parts[2][text]
      &patch=  $parts[3][text]
      &prerel= (if (!=s $parts[4][text] '') { put $parts[4][text] } else { put $nil })
      &build=  (if (!=s $parts[5][text] '') { put $parts[5][text] } else { put $nil })
    ]
  } else {
    put $nil
  }
}

fn cmp {|v1 v2 &allow-v=$nil|
  validate $v1 &allow-v=$allow-v
  validate $v2 &allow-v=$allow-v
  var p1 = (parse $v1 &allow-v=$allow-v)
  var p2 = (parse $v2 &allow-v=$allow-v)
  var comp = (-part-compare $p1 $p2)
  if (!= $comp 0) {
    # If there is a difference in the MAJOR.MINOR.PATCH part, that's the result
    put $comp
  } else {
    # Otherwise, check the prerelease strings
    var prerel1 prerel2 = $p1[prerel] $p2[prerel]
    if (and $prerel1 $prerel2) {
      # If both prerel strings are present, compare them
      -signed-compare $'<s~' $prerel1 $prerel2
    } else {
      # Otherwise, the one without a string is "more than" the other
      -signed-compare {|v1 v2| and $v1 (not $v2) } $prerel1 $prerel2
    }
  }
}

fn -seq-compare {|op expected @vers &allow-v=$nil|
  var res = $true
  var last = $false
  each {|v|
    if $last {
      set res = (and $res ($op (cmp $last $v &allow-v=$allow-v) $expected))
    }
    set last = $v
  } $vers
  put $res
}

fn '<'    {|@vers &allow-v=$nil| -seq-compare $builtin:eq~      1 $@vers &allow-v=$allow-v }
fn '>'    {|@vers &allow-v=$nil| -seq-compare $builtin:eq~     -1 $@vers &allow-v=$allow-v }
fn eq     {|@vers &allow-v=$nil| -seq-compare $builtin:eq~      0 $@vers &allow-v=$allow-v }
fn not-eq {|@vers &allow-v=$nil| -seq-compare $builtin:not-eq~  0 $@vers &allow-v=$allow-v }
fn '<='   {|@vers &allow-v=$nil| -seq-compare $builtin:not-eq~ -1 $@vers &allow-v=$allow-v }
fn '>='   {|@vers &allow-v=$nil| -seq-compare $builtin:not-eq~  1 $@vers &allow-v=$allow-v }
