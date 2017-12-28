use re

fn push [@arg]{
  msg = "Markup fixes"
  if (< 0 (count $arg)) {
    msg = (joins " " $arg)
  }
  BRANCH=(git symbolic-ref HEAD | sed -e 's|^refs/heads/||')
  REPO=(git remote -v | head -1 | sed 's/^.*oreilly\.com\///; s/\.git.*$//')
  echo (edit:styled "Committing and pushing changes to "$REPO", branch "$BRANCH"..." yellow) > /dev/tty
  st=?(git ci -a -m $msg > /dev/tty)
  git push atlas $BRANCH > /dev/tty
  put $BRANCH $REPO
}

fn buildonly [type branch repo]{
  echo (edit:styled "Building "$type" on "$repo", branch "$branch"..." yellow) > /dev/tty
  atlas build $E:ATLAS_TOKEN $repo $type $branch | tee build/build.out > /dev/tty
  URL EXT = (cat build/build.out | eawk [line @f]{
      m = (or (re:find '(?i)'$type':\s+(.*\.([a-z]+))$' $line) $false)
      if $m {
        put $m[groups][1 2][text]
      }
  })
  echo (edit:styled "Fetching and opening build "$URL green) > /dev/tty
  OUTFILE = "../atlas-builds/plain-format/atlas-plain."$EXT
  curl -o $OUTFILE $URL > /dev/tty 2>&1
  put $OUTFILE
}

fn build [type @arg]{
  BRANCH REPO = (push $@arg)
  OUTFILE = (buildonly $type $BRANCH $REPO)
  open $OUTFILE
}

fn all [@arg]{
  BRANCH REPO = (push $@arg)
  FILES = []
  for ext [pdf epub mobi html] {
    FILES = [ $@FILES (buildonly $ext $BRANCH $REPO) ]
  }
  pprint $FILES
}
