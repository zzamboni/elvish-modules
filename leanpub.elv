api-key = ''

fn preview [slug]{
  pprint (curl -s -d "api_key="$api-key https://leanpub.com/$slug/preview.json | from-json)
}

fn status [slug]{
  status = (curl -s "https://leanpub.com/"$slug"/job_status?api_key="$api-key | from-json)
  if (has-key $status backtrace) {
    file = (mktemp)
    echo $status[backtrace] > $file
    del status[backtrace]
    status[error-log] = $file
  }
  put $status
  if (has-key $status error-log) {
    fail "An error occurred. The backtrace is at "$status[error-log]
  }
}

fn watch [slug]{
  s = (status $slug)
  while (not-eq $s [&]) {
    pprint $s
    sleep 5
    s = (status $slug)
  }
}
