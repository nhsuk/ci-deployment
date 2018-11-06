if [ "$PROTOTYPE" == "TRUE" ]; then
  {
    echo "DB_TYPE=sqlite"
    echo 'TRAEFIK_RULE="Host: ${RANCHER_STACK_NAME}.${TRAEFIK_DOMAIN}"'
  } >> answers.txt
fi
