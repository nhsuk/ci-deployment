if [ "$PROTOTYPE" == "TRUE" ]; then
  {
    echo "DB_TYPE=sqlite"
    echo "TRAEFIK_RULE='Host: ${RANCHER_STACK_NAME//_/-}.${TRAEFIK_DOMAIN}'"
    echo "HOST_BETA=${RANCHER_STACK_NAME//_/-}.${TRAEFIK_DOMAIN}"
  } >> answers.txt
fi
