fn add-before-readline {|@hooks|
  each {|hook|
    if (not (has-value $edit:before-readline $hook)) {
      set edit:before-readline = [ $@edit:before-readline $hook ]
    }
  } $hooks
}

fn add-after-readline {|@hooks|
  each {|hook|
    if (not (has-value $edit:after-readline $hook)) {
      set edit:after-readline = [ $@edit:after-readline $hook ]
    }
  } $hooks
}
