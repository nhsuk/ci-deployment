if [ "$BRANCH_BUILD" == "TRUE" ]; then
  {
    branch="${CI_COMMIT_REF_SLUG//_/-}"
    if [ "${branch:0:5}" == "proto" ]; then
      branch="prototype"
    fi
    host="${CI_PROJECT_NAME//_/-}-${branch}"
    domain="dev.beta.nhschoices.net"
    echo "DB_TYPE=sqlite"
    echo "TRAEFIK_RULE='Host: ${host}.${domain}'"
    echo "HOST_BETA=${host}.${domain}"
    echo "DEPLOY_URL='${host}.${domain}'"
  } >> answers.txt
fi
