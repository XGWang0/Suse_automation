*** Variables ***
${HAMSTA_HOST}            {{ hamsta.fqdn }}
${HAMSTA_BASE_URL}        http://${HAMSTA_HOST}/hamsta/
${QADB_HOST}              {{ qadb.fqdn }}
${QADB_BASE_URL}          http://${QADB_HOST}/qadb/
${USER_LOGIN}             {{ testuser.login }}
${USER_PASSWORD}          {{ testuser.password }}
${USER_NAME}              {{ testuser.name }}

