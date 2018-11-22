if [ "$BRANCH_BUILD" == "TRUE" ]; then
  {
    host="${CI_PROJECT_NAME//_/-}-${CI_COMMIT_REF_SLUG//_/-}"
    domain="dev.beta.nhschoices.net"
    echo "DB_TYPE=sqlite"
    echo "TRAEFIK_RULE='Host: ${host}.${domain}'"
    echo "HOST_BETA=${host}.${domain}"
    echo "DEPLOY_URL='${host}.${domain}'"
  } >> answers.txt
fi
