use str

var api-key = ''

var write-api-key = ''

var api-url = 'https://api.eu.opsgenie.com/v2'

fn request {|url &params=[&]|
  var auth-hdr = 'Authorization: GenieKey '$api-key
  set params = [(keys $params | each {|k| put "--data-urlencode" $k"="$params[$k] })]
  curl -G -s $@params -H $auth-hdr $url | from-json
}

fn post-request {|url data|
  var auth-hdr = 'Authorization: GenieKey '$write-api-key
  var json-data = (put $data | to-json)
  curl -X POST -H $auth-hdr -H 'Content-Type: application/json' --data $json-data $url
}

fn request-data {|url &paged=$true|
  var response = (request $url)
  var data = $response[data]
  if $paged {
    while (and (has-key $response paging) (has-key $response[paging] next)) {
      set response = (request $response[paging][next])
      var newdata = $response[data]
      set data = [ $@data $@newdata ]
    }
  }
  put $data
}

fn admins {
  var admins = [&]
  var url = $api-url'/teams'
  put (all (request-data $url))[name] | each {|id|
    #put $id
    try {
      put (all (request-data $url'/'$id'?identifierType=name')[members]) | each {|user|
        #put $user
        if (eq $user[role] admin) {
          set admins[$user[user][username]] = $id
        }
      }
    } except e {
      # This is here to skip teams without members
    }
  }
  put $admins
}

fn url-for {|what &params=[&]|
  var params-str = (keys $params | each {|k| put $k"="$params[$k] } | str:join "&")
  put $api-url'/'$what'?'$params-str
}

fn list {|what &keys=[name] &params=[&]|
  each {|r|
    var res = [&]
    if (eq $keys []) {
      set res = $r
    } else {
      each {|k|
        set res[$k] = $r[$k]
      } $keys
    }
    put $res
  } (request-data (url-for $what &params=$params))
}

fn get {|what &params=[&]|
  request (url-for $what &params=$params)
}

fn get-data {|what &params=[&]|
  request-data (url-for $what &params=$params)
}

fn create-user {|username fullname role otherfields &team=""|
  var payload = $otherfields
  set payload[username] = $username
  set payload[fullName] = $fullname
  set payload[role] = [&name= $role]
  post-request (url-for users) $payload
  echo ""
  if (not-eq $team "") {
    var data = [ &user= [ &username= (echo $username | tr '[A-Z]' '[a-z]') ] ]
    post-request (url-for "teams/"$team"/members" &params=[ &teamIdentifierType= name ]) $data
    echo ""
  }
}

fn add-users-to-team {|team @users|
  each {|username|
    var data = [ &user= [ &username= (echo $username | tr '[A-Z]' '[a-z]') ] ]
    post-request (url-for "teams/"$team"/members" &params=[ &teamIdentifierType= name ]) $data
    echo ""
  } $users
}

fn post-api {|path data &params=[&] |
  var url = (url-for $path &params=$params)
  post-request $url $data
}

fn api {|path &params=[&] |
  var url = (url-for $path)
  request $url &params=$params
}
