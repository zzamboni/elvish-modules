use str

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
  }
  $op get item $@options $item
}

fn get-item {|item &options=[] &fields=[]|
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
