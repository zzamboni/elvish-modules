use str

var api-key = $nil
var api-key-fn = $nil
var json-output = $false

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

fn -post {|url|
  curl -s -d "api_key="(api-key) $url | from-json
}

fn -get {|url|
  curl -s $url | from-json
}

fn -request-error {|res|
  if (has-key $res errors) {
    put (str:join "; " $res[errors])
  } elif (has-key $res error) {
    put $res[error]
  } elif (and (has-key $res success) (not $res[success])) {
    put "request failed"
  } else {
    put $nil
  }
}

fn -fail-if-error {|res context|
  var err = (-request-error $res)
  if $err {
    fail $context": "$err
  }
}

fn -map-value {|m key &default=$nil|
  if (and (has-key $m $key) $m[$key]) {
    put $m[$key]
  } else {
    put $default
  }
}

fn -print-action-result {|action slug res|
  -fail-if-error $res "Leanpub "$action
  echo "Started "$action" for "$slug"."
}

fn preview {|@args &json=$json-output|
  var slug = (get-slug $@args)
  var res = (-post https://leanpub.com/$slug/preview.json)
  if $json {
    pprint $res
  } else {
    -print-action-result preview $slug $res
  }
}

fn subset {|@args &json=$json-output|
  var slug = (get-slug $@args)
  var res = (-post https://leanpub.com/$slug/preview/subset.json)
  if $json {
    pprint $res
  } else {
    -print-action-result "subset preview" $slug $res
  }
}

fn publish {|@args &json=$json-output|
  var slug = (get-slug $@args)
  var res = (-post https://leanpub.com/$slug/publish.json)
  if $json {
    pprint $res
  } else {
    -print-action-result publish $slug $res
  }
}

fn -status-line {|status|
  put $status[num]" / "$status[total]"    "$status[message]
}

fn -fetch-status {|slug|
  var status = (-get "https://leanpub.com/"$slug"/job_status.json?api_key="(api-key))
  if (has-key $status backtrace) {
    var file = (mktemp)
    echo $status[backtrace] > $file
    del status[backtrace]
    set status[error-log] = $file
  }
  var err = (-request-error $status)
  if $err {
    var backtrace-msg = ""
    if (has-key $status error-log) {
      set backtrace-msg = " (backtrace: "$status[error-log]")"
    }
    fail "Leanpub status failed: "$err$backtrace-msg
  }
  put $status
}

fn status {|@args &json=$json-output|
  var slug = (get-slug $@args)
  var s = (-fetch-status $slug)
  if $json {
    pprint $s
  } elif (eq $s [&]) {
    echo "No Leanpub job is currently running for "$slug"."
  } else {
    echo (-status-line $s)
    if (has-key $s job_type) {
      echo "Job: "$s[job_type]
    }
  }
}

fn watch {|@args &json=$json-output|
  var slug = (get-slug $@args)
  var s = (-fetch-status $slug)
  while (not-eq $s [&]) {
    if $json {
      pprint $s
    } else {
      printf "\r\033[2K%s" (-status-line $s)
    }
    sleep 5
    set s = (-fetch-status $slug)
  }
  if (not $json) {
    printf "\n"
  }
}

fn preview-and-watch {|@args &json=$json-output|
  var slug = (get-slug $@args)
  preview &json=$json $slug
  watch &json=$json $slug
}

fn subset-and-watch {|@args &json=$json-output|
  var slug = (get-slug $@args)
  subset &json=$json $slug
  watch &json=$json $slug
}

fn publish-and-watch {|@args &json=$json-output|
  var slug = (get-slug $@args)
  publish &json=$json $slug
  watch &json=$json $slug
}

fn do-subset {|@args &json=$json-output|
  var msg = (echo $@args)
  git ci -a -m $msg
  git push
  subset-and-watch &json=$json
}

fn info {|@args &json=$json-output|
  var slug = (get-slug $@args)
  var info = (-get "https://leanpub.com/"$slug".json?api_key="(api-key))
  -fail-if-error $info "Leanpub info"
  if $json {
    pprint $info
  } else {
    var title = $info[title]
    if (has-key $info subtitle) {
      set title = $title": "$info[subtitle]
    }
    echo $title
    if (has-key $info author_string) {
      echo "Author: "$info[author_string]
    }
    echo "Slug: "$info[slug]
    if (has-key $info url) {
      echo "URL: "$info[url]
    }
    if (has-key $info about_the_book) {
      echo "About: "$info[about_the_book]
    }
    if (has-key $info minimum_paid_price) {
      echo "Minimum price: $"$info[minimum_paid_price]
    }
    if (has-key $info suggested_price) {
      echo "Suggested price: $"$info[suggested_price]
    }
    if (or (has-key $info page_count) (has-key $info page_count_published)) {
      var preview-pages = (-map-value $info page_count &default="?")
      var published-pages = (-map-value $info page_count_published &default="?")
      echo "Pages: "$preview-pages" preview, "$published-pages" published"
    }
    if (or (has-key $info word_count) (has-key $info word_count_published)) {
      var preview-words = (-map-value $info word_count &default="?")
      var published-words = (-map-value $info word_count_published &default="?")
      echo "Words: "$preview-words" preview, "$published-words" published"
    }
    if (has-key $info total_copies_sold) {
      echo "Copies sold: "$info[total_copies_sold]
    }
    if (has-key $info total_revenue) {
      echo "Revenue: $"$info[total_revenue]
    }
    if (has-key $info possible_reader_count) {
      echo "Possible readers: "$info[possible_reader_count]
    }
    if (has-key $info last_published_at) {
      echo "Last published: "$info[last_published_at]
    }
    if (has-key $info pdf_preview_url) {
      echo "PDF preview: "$info[pdf_preview_url]
    }
    if (has-key $info epub_preview_url) {
      echo "EPUB preview: "$info[epub_preview_url]
    }
    if (has-key $info pdf_published_url) {
      echo "PDF published: "$info[pdf_published_url]
    }
    if (has-key $info epub_published_url) {
      echo "EPUB published: "$info[epub_published_url]
    }
  }
}
