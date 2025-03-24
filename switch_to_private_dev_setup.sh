#!/bin/bash

# helper functions
function print_info(){
  printf "$(tput bold)%s$(tput sgr0)\n" "${1}"
}

function print_warn(){
  printf "$(tput bold)$(tput setaf 214)%s$(tput sgr0)\n" "${1}"
}


# tool check
if ! command -v sdk &> /dev/null; then
  print_warn "-> sdkman not sourced properly...making it available <-"
  source "$HOME/.sdkman/bin/sdkman-init.sh"
fi


# setting environment
if [[ "$(sdk current maven)" == *"_private" ]]; then
  print_msg "::: Maven is correctly set to a private version :::"
else
  sdk default maven 3.9.2_private
fi

exit 0