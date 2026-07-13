#!/bin/bash

# Import certificate into Java keystore
CERT_FILE="/usr/local/share/ca-certificates/milkyway.crt"
if [ -f "$CERT_FILE" ]; then
    echo "Found certificate: $CERT_FILE. Importing into Java keystore..."
    $JAVA_HOME/bin/keytool -importcert -trustcacerts -file "$CERT_FILE" \
        -alias milkyway -keystore $JAVA_HOME/lib/security/cacerts \
        -storepass changeit -noprompt || echo "Certificate already exists or failed to import"
else
    echo "WARNING: Certificate file not found: $CERT_FILE"
fi

PROPERTIES_FILE="/usr/local/tomcat/conf/robak-rest.properties"

if [ -f "$PROPERTIES_FILE" ]; then
  echo "Found properties file: $PROPERTIES_FILE. Processing..."
  # Use a while loop for compatibility
  while IFS='=' read -r key value; do
    # Ignore empty lines and comments
    if [[ ! "$key" =~ ^\s*# && -n "$key" ]]; then
      # Remove any spaces from the key
      key=$(echo "$key" | tr -d '[:space:]')
      # Add the property to CATALINA_OPTS, wrapping it in quotes
      # This is crucial so Tomcat correctly interprets each parameter
      CATALINA_OPTS="$CATALINA_OPTS \"-D$key=$value\""
    fi
  done < "$PROPERTIES_FILE"

  # Use eval to correctly interpret quotes when exporting
  eval "export CATALINA_OPTS=\"$CATALINA_OPTS\""

  echo "CATALINA_OPTS after processing: $CATALINA_OPTS"
else
  echo "WARNING: Properties file not found: $PROPERTIES_FILE"
fi
export CATALINA_OPTS="$CATALINA_OPTS -Dserver.servlet.context-path=/api"