api-key = ''

write-api-key = ''

api-url = 'https://api.eu.opsgenie.com/v2'

fn request [url &params=[&]]{
  auth-hdr = 'Authorization: GenieKey '$api-key
  params = [(keys $params | each [k]{ put "--data-urlencode" $k"="$params[$k] })]
  curl -G -s $@params -H $auth-hdr $url | from-json
}

fn post-request [url data]{
  auth-hdr = 'Authorization: GenieKey '$write-api-key
  json-data = (put $data | to-json)
  curl -X POST -H $auth-hdr -H 'Content-Type: application/json' --data $json-data $url
}

fn request-data [url &paged=$true]{
  response = (request $url)
  data = $response[data]
  if $paged {
    while (and (has-key $response paging) (has-key $response[paging] next)) {
      response = (request $response[paging][next])
      newdata = $response[data]
      data = [ $@data $@newdata ]
    }
  }
  put $data
}

fn admins {
  admins = [&]
  url = $api-url'/teams'
  put (explode (request-data $url))[name] | each [id]{
    #put $id
    try {
      put (explode (request-data $url'/'$id'?identifierType=name')[members]) | each [user]{
        #put $user
        if (eq $user[role] admin) {
          admins[$user[user][username]] = $id
        }
      }
    } except e {
      # This is here to skip teams without members
    }
  }
  put $admins
}

fn url-for [what &params=[&]]{
  params-str = (keys $params | each [k]{ put $k"="$params[$k] } | joins "&")
  put $api-url'/'$what'?'$params-str
}

fn list [what &keys=[name] &params=[&]]{
  each [r]{
    res = [&]
    if (eq $keys []) {
      res = $r
    } else {
      each [k]{
        res[$k] = $r[$k]
      } $keys
    }
    put $res
  } (request-data (url-for $what &params=$params))
}

fn get [what &params=[&]]{
  request (url-for $what &params=$params)
}

fn get-data [what &params=[&]]{
  request-data (url-for $what &params=$params)
}

fn create-user [username fullname role otherfields &team=""]{
  payload = $otherfields
  payload[username] = $username
  payload[fullName] = $fullname
  payload[role] = [&name= $role]
  post-request (url-for users) $payload
  echo ""
  if (not-eq $team "") {
    data = [ &user= [ &username= (echo $username | tr '[A-Z]' '[a-z]') ] ]
    post-request (url-for "teams/"$team"/members" &params=[ &teamIdentifierType= name ]) $data
    echo ""
  }
}

fn add-users-to-team [team @users]{
  each [username]{
    data = [ &user= [ &username= (echo $username | tr '[A-Z]' '[a-z]') ] ]
    post-request (url-for "teams/"$team"/members" &params=[ &teamIdentifierType= name ]) $data
    echo ""
  } $users
}

fn post-api [path data &params=[&] ]{
  url = (url-for $path &params=$params)
  post-request $url $data
}

fn api [path &params=[&] ]{
  url = (url-for $path)
  request $url &params=$params
}
