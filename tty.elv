use re
use str

fn with-stty [args cmd~]{
  local:stty = (stty -g)
  try { stty $@args; cmd } finally { stty $stty }
}

fn csi [@cmd]{
  print "\e["(str:join '' [(
        each [e]{
          if (eq (kind-of $e) list) {
            str:join ';' $e
          } else {
            put $e
          }
  } $cmd)]) >/dev/tty
}

fn cursor-pos {
  local:res = (with-stty [-echo raw] { csi 6 n; read-upto R </dev/tty })
  put (re:find '\[(\d+);(\d+)R' $res)[groups][{1,2}][text]
}

# Short name alias according to https://en.wikipedia.org/wiki/ANSI_escape_code
dsr~ = $cursor-pos~
