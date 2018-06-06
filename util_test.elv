use github.com/zzamboni/elvish-modules/test

test:set util:dotify-string {
  use github.com/zzamboni/elvish-modules/util
  test:is { util:dotify-string "somelongstring" 5 } "somel…"
  test:is { util:dotify-string "short" 5 } "short"
}
