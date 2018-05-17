api-key = ''

fn request [url]{
  auth-hdr = 'Authorization: GenieKey '$api-key
  curl -s -X GET -H $auth-hdr $url | from-json
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
  url = 'https://api.opsgenie.com/v2/teams'
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
  put 'https://api.opsgenie.com/v2/'$what'?'$params-str
}

fn list [what &keys=[name] &params=[&]]{
  auth-hdr = 'Authorization: GenieKey '$api-key
  put (explode (request-data (url-for &params=$params $what)))[$@keys]
}

fn get [what &params=[&]]{
  auth-hdr = 'Authorization: GenieKey '$api-key
  params-str = (keys $params | each [k]{ put $k"="$params[$k] } | joins "&")
  url = 'https://api.opsgenie.com/v2/'$what'?'$params-str
  request $url
}

fn get-data [what &params=[&]]{
  auth-hdr = 'Authorization: GenieKey '$api-key
  params-str = (keys $params | each [k]{ put $k"="$params[$k] } | joins "&")
  url = 'https://api.opsgenie.com/v2/'$what'?'$params-str
  request-data $url
}
