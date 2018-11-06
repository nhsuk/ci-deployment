if [ "$PROTOTYPE" == "TRUE" ]; then
  {
    host="${RANCHER_STACK_NAME//_/-}.${TRAEFIK_DOMAIN}"
    echo "DB_TYPE=sqlite"
    echo 'TRAEFIK_RULE="Host: ${host}"'
    echo "HOST_BETA=${host}"
  } >> answers.txt
fi
