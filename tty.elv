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

fn csi-report [delim @cmd]{
  with-stty [-echo raw] { csi $@cmd; read-upto $delim </dev/tty }
}

fn cursor-pos {
  local:res = (csi-report R 6 n)
  put (re:find '\[(\d+);(\d+)R' $res)[groups][{1,2}][text]
}

# Short name alias according to https://en.wikipedia.org/wiki/ANSI_escape_code
dsr~ = $cursor-pos~
