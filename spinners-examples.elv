use github.com/zzamboni/elvish-modules/spinners

spinners:run { sleep 3 }

spinners:run &spinner=arrow &title="Loading modules" { sleep 3 }

spinners:run &title=(styled "Counting files" blue) &style=green { fd . . } | count
fd . . | spinners:run &title="Counting characters in filenames" { each [f]{ all $f } } | count

spinners:run &title="Starting title" &persist=$true [s]{
  sleep 3
  spinners:attr $s title "New title!"
  sleep 3
  spinners:attr $s spinner shark
  spinners:attr $s style [ red ]
  sleep 3
  spinners:attr $s persist success
}

spinners:persist-symbols[unicorn] = [ &symbol="🦄" &color=default ]
spinners:run &title="Getting a unicorn" &persist=unicorn { sleep 3 }

s = (spinners:new &title="Test spinner" &persist=status &hide-exception)

spinners:start $s

sleep 3
spinners:attr $s title "New title!"
sleep 2
spinners:persist $s
sleep 1
spinners:attr $s spinner shark
sleep 3
spinners:attr $s status ?(fail error)
spinners:persist-and-new $s &indent=2 &title=(styled "Next step" blue)
sleep 3

spinners:stop $s
