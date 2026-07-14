#!/bin/bash

PROPERTIES_FILE="/usr/local/tomcat/conf/andromeda-authorization.properties"

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