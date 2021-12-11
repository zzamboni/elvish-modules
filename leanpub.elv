use str

var api-key = $nil
var api-key-fn = $nil

fn api-key {
  if $api-key {
    put $api-key
  } elif $api-key-fn {
    set api-key = ($api-key-fn)
    put $api-key
  } else {
    fail "Please set leanpub:api-key or leanpub:api-key-fn"
  }
}

fn get-slug {|@args|
  if (eq $args []) {
    put [(str:split / $pwd)][-1]
  } else {
    put $args[0]
  }
}

fn preview {|@args|
  var slug = (get-slug $@args)
  pprint (curl -s -d "api_key="(api-key) https://leanpub.com/$slug/preview.json | from-json)
}

fn subset {|@args|
  var slug = (get-slug $@args)
  pprint (curl -s -d "api_key="(api-key) https://leanpub.com/$slug/preview/subset.json | from-json)
}

fn publish {|@args|
  var slug = (get-slug $@args)
  pprint (curl -s -d "api_key="(api-key) https://leanpub.com/$slug/publish.json | from-json)
}

fn status {|@args|
  var slug = (get-slug $@args)
  var status = (curl -s "https://leanpub.com/"$slug"/job_status?api_key="(api-key) | from-json)
  if (has-key $status backtrace) {
    var file = (mktemp)
    echo $status[backtrace] > $file
    del status[backtrace]
    set status[error-log] = $file
  }
  put $status
  if (has-key $status error-log) {
    fail "An error occurred. The backtrace is at "$status[error-log]
  }
}

fn watch {|@args|
  var slug = (get-slug $@args)
  var s = (status $slug)
  while (not-eq $s [&]) {
    pprint $s
    sleep 5
    set s = (status $slug)
  }
}

fn preview-and-watch {|@args|
  var slug = (get-slug $@args)
  preview $slug
  watch $slug
}

fn subset-and-watch {|@args|
  var slug = (get-slug $@args)
  subset $slug
  watch $slug
}

fn publish-and-watch {|@args|
  var slug = (get-slug $@args)
  publish $slug
  watch $slug
}

fn do-subset {|@args|
  var msg = (echo $@args)
  git ci -a -m $msg
  git push
  subset-and-watch
}

fn info {|@args|
  var slug = (get-slug $@args)
  pprint (curl -s "https://leanpub.com/"$slug".json?api_key="(api-key) | from-json)
}
