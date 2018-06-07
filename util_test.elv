use github.com/zzamboni/elvish-modules/test
use github.com/zzamboni/elvish-modules/util

(test:set github.com/zzamboni/elvish-modules/util \
  (test:set dotify-string \
    (test:is { eq (util:dotify-string "somelongstring" 5) "somel…" } Long string gets dotified) \
    (test:is { eq (util:dotify-string "short" 5) "short" } Equal-as-limit string stays the same) \
    (test:is { eq (util:dotify-string "bah" 5) "bah" } Short string stays the same)))
