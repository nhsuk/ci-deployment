#!/bin/bash
# shellcheck disable=SC2059
# rule SC2059 about variables in printf doesn't seem to lead to more legible code

# Simple utility script to display current travis environment values and to enter
# values or leave existing ones unmodified.

grn=$'\e[1;32m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
end=$'\e[0m'

setValue() {
    echo -n "${1}?: "
    read -r value
    if [ "${value}" != "" ]
    then
      travis env set "--${2:-private}" "$1" "$value"
    fi
}

setPrivateValue() {
  setValue "$1" private
}

setPublicValue() {
  setValue "$1" public
}

displayMessage() {
  printf "\\n%s (%s)\\n\\n" \
    "${grn}${1} Environment Variables${end}" \
    "${blu}Enter a value or press return to leave the value unchanged${end}"
}


public_values="VAULT_SERVER"
private_values="VAULT_TOKEN"

printf "${mag}The current environment variables are:${end}\\n\\n"
travis env list

displayMessage "Private"
for i in $private_values
do
  setPrivateValue "$i"
done

displayMessage "Public"
for i in $public_values
do
  setPublicValue "$i"
done
