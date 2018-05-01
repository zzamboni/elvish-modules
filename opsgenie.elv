api-key = ''

fn admins {
  admins = [&]
  auth-hdr = 'Authorization: GenieKey '$api-key
  url = 'https://api.opsgenie.com/v2/teams'
  put (explode (curl -s -X GET -H $auth-hdr $url | from-json)[data])[name] | each [id]{
    #put $id
    try {
      put (explode (curl -s -X GET -H $auth-hdr $url'/'$id'?identifierType=name' | from-json)[data][members]) | each [user]{
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

fn list [what &key=name]{
  auth-hdr = 'Authorization: GenieKey '$api-key
  url = 'https://api.opsgenie.com/v2/'$what
  put (explode (curl -s -X GET -H $auth-hdr $url | from-json)[data])[$key]
}
