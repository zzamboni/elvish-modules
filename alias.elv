dir = ~/.elvish/aliases

fn def [&verbose=false name @cmd]{
  file = $dir/$name.elv
  echo "#alias:def" $name $@cmd > $file
  echo fn $name '[@_args]{' $@cmd '$@_args }' >> $file
  if (not-eq $verbose false) {
    echo (edit:styled "Defining alias "$name green)
  }
  is_ok = ?(-source $file)
  if (not $is_ok) {
    echo (edit:styled "Your alias definition has a syntax error. Please recheck it.\nError: "(echo $is_ok) red)
    rm $file
  }
}

fn new [@arg]{ def $@arg }

fn bash_alias [@args]{
  line = $@args
  name cmd = (splits &max=2 '=' $line)
  def $name $cmd
}

fn list {
  _ = ?(grep -h '^#alias:def ' $dir/*.elv | sed 's/^#//')
}

fn ls { list } # Alias for list

fn undef [name]{
  file = $dir/$name.elv
  if ?(test -f $file) {
    # Remove the definition file
    rm $file
    # Remove the function in the current session
    tmpf = (mktemp)
    echo  "del "$name"~" > $tmpf
    -source $tmpf
    rm -f $tmpf
    echo (edit:styled "Alias "$name" removed." green)
  } else {
    echo (edit:styled "Alias "$name" does not exist." red)
  }
}

fn rm [@arg]{ undef $@arg }

if (not ?(test -d $dir)) {
  mkdir -p $dir
}

for file [(_ = ?(put $dir/*.elv))] {
  is_ok = ?(-source $file)
  if (not $is_ok) {
    echo (edit:styled "Error when loading alias file "$file" - please check it." red)
  }
}
