#!/usr/bin/env bash
set -euo pipefail
source scripts/env.sh
export SSL_CERT_FILE=/run/system-ca.pem
export CURL_CA_BUNDLE=/run/system-ca.pem
# The container user's actual home is writable; HOME is not changed.
if [[ -f /run/proxy-ca.pem ]]; then
  _worktime_truststore="$(mktemp /tmp/worktime-java-trust.XXXXXX)"
  cp /etc/ssl/certs/java/cacerts "$_worktime_truststore"
  keytool -importcert -noprompt -alias worktime-session-proxy \
    -file /run/proxy-ca.pem -keystore "$_worktime_truststore" \
    -storepass changeit >/dev/null 2>&1
  export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -Djavax.net.ssl.trustStore=$_worktime_truststore"
fi
if [[ -n "${HTTPS_PROXY:-}" ]]; then
  _worktime_proxy_options="$(python3 - <<'PY'
import os
from urllib.parse import urlsplit
p = urlsplit(os.environ['HTTPS_PROXY'])
if p.scheme != 'http' or not p.hostname or p.username or p.password:
    raise SystemExit('Unsupported SDK proxy configuration')
port = p.port or 80
print(f'-Dhttps.proxyHost={p.hostname} -Dhttps.proxyPort={port} '
      f'-Dhttp.proxyHost={p.hostname} -Dhttp.proxyPort={port} '
      '-Dhttp.nonProxyHosts=localhost|127.*')
PY
)"
  export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} $_worktime_proxy_options"
fi
if [[ -x "$FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart" ]]; then
  "$FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart" --disable-analytics >/dev/null
fi
exec "$@"
