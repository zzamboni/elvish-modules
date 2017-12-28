# Alias management
# Diego Zamboni <diego@zzamboni.org>
#
# Usage:
#
# - In your rc.elv, add `use alias`
# - To define an alias: `alias:new alias command`
# - To list existing aliases: `alias:list`
# - To remove an alias: `alias:rm alias`
#   NOTE: the change will only take effect in future shells
# - alias:bash_alias is a wrapper which understands the bash syntax
#   `name=command` for defining aliases.
#
# Each alias is stored in a separate file under $alias:dir
# (~/.elvish/aliases by default).

dir = ~/.elvish/aliases

#----------------------------------------------------------------------
# List aliases
#----------------------------------------------------------------------

fn list {
  _ = ?(grep -h '^#alias:def ' $dir/*.elv | sed 's/^#//')
}

fn ls { list } # Alias for list

#----------------------------------------------------------------------
# Define aliases
#----------------------------------------------------------------------

fn def [name @cmd]{
  file = $dir/$name.elv
  echo "#alias:def" $name $@cmd > $file
  echo fn $name '[@_args]{' $@cmd '$@_args }' >> $file
  echo (edit:styled "Defining alias "$name green)
  is_ok = ?(-source $file)
  if (not $is_ok) {
    echo (edit:styled "Your alias definition has a syntax error. Please recheck it.\nError: "(echo $is_ok) red)
    rm $file
  }
}

# Alias for def
fn new [@arg]{ def $@arg }

# Wrapper which understands the bash syntax `alias name=command`
fn bash_alias [@args]{
  line = $@args
  name cmd = (splits '=' $line)
  def $name $cmd
}


#----------------------------------------------------------------------
# Remove aliases
#----------------------------------------------------------------------

fn undef [name]{
  file = $dir/$name.elv
  if ?(test -f $file) {
    echo (edit:styled "Removing file for alias "$name". The change will take effect in new shells only." yellow)
    rm $file
  } else {
    echo (edit:styled "Alias "$name" does not exist.")
  }
}

# Alias for undef
fn rm [@arg]{ undef $@arg }

#----------------------------------------------------------------------
# Init code - this runs when the library is loaded
#----------------------------------------------------------------------

# Create alias directory if it doesn't exist
if (not ?(test -d $dir)) {
  mkdir -p $dir
}

# Load all the existing alias definitions
for file [(_ = ?(put $dir/*.elv))] {
  is_ok = ?(-source $file)
  if (not $is_ok) {
    echo (edit:styled "Error when loading alias file "$file" - please check it." red)
  }
}
