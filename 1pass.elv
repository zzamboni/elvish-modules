use str
use re
use path

var account = my

var op = (external op)

var password-field = "password"

fn session-token {|&account=$account|
  if (has-env OP_SESSION_$account) {
    get-env OP_SESSION_$account
  } else {
    put $nil
  }
}

fn set-token {|&account=$account token|
  set-env OP_SESSION_$account $token
}

fn signin {|&account=$account &no-refresh=$false|
  var refresh-opts = [ --session (session-token) ]
  if $no-refresh {
    set refresh-opts = []
  }
  set-token &account=$account ($op signin --raw $@refresh-opts </dev/tty)
}

fn get-item-raw {|item &options=[] &fields=[]|
  signin
  if (not-eq $fields []) {
    set options = [ $@options --fields (str:join , $fields) ]
  } else {
    set options = [ $@options ]
  }
  $op item get $@options $item | slurp
}

fn get-item {|item &options=[] &fields=[]|
  if (!= (count $fields) 1) {
    set options = [ $@options --format json ]
  }
  var item-str = (get-item-raw &options=$options &fields=$fields $item)
  if (== (count $fields) 1) {
    put $item-str
  } else {
    echo $item-str | from-json
  }
}

fn get-password {|item|
  get-item &fields=[$password-field] $item
}

var op_plugins_file = ~/.config/op/plugins.sh

fn read-aliases {
  if (path:is-regular $op_plugins_file) {
    cat $op_plugins_file | each {|l|
      var m = [(re:find '^alias (\w+)="(.*?)"' $l)]
      if (not-eq $m []) {
        var name = $m[0][groups][1][text]
        var cmd = [(edit:wordify $m[0][groups][2][text])]
        var fndef = (print 'edit:add-var '$name'~ {|@_args| ' $@cmd '$@_args }' | slurp)
        eval $fndef
      }
      if (re:find '^export' $l) {
        var _ key val = (re:split &max=3 '[ =]' $l)
        set-env $key $val
      }
    }
  }
}
