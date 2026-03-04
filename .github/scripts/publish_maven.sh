
#!/bin/bash
# publish-maven.sh
# Builds, signs, and publishes to Maven Central using central-publishing-maven-plugin
set -euo pipefail

SETTINGS_FILE="./settings.xml"

# Auto-cleanup settings.xml on exit (success or failure)
trap 'echo "Cleaning up settings.xml..."; rm -f "${SETTINGS_FILE}"' EXIT

echo "${MVN_GPG_KEYS_GPGPRIVATEKEY}"

echo "=== Step 1: Import GPG private key ==="
printf '%s' "${MVN_GPG_KEYS_GPGPRIVATEKEY}" | gpg --batch --import
echo "GPG key imported successfully."

echo "=== Step 2: Write minimal settings.xml ==="
cat > "${SETTINGS_FILE}" <<EOF
<settings>
  <servers>
    <server>
      <id>central</id>
      <username>${MVN_ACCOUNT_KEYS_USERNAME}</username>
      <password>${MVN_ACCOUNT_KEYS_PASSWORD}</password>
    </server>
  </servers>
</settings>
EOF

echo "settings.xml written."

echo "=== Step 3: Build artifacts ==="
mvn clean install --no-transfer-progress

echo "=== Step 4: Deploy to Maven Central ==="

mvn clean deploy -s "${SETTINGS_FILE}" -pl sdk -P publishing -DskipTests -Dgpg.passphrase="${MVN_GPG_KEYS_GPGPASSPHRASE}"
mvn clean deploy -s "${SETTINGS_FILE}" -pl sdk-testing -P publishing -DskipTests -Dgpg.passphrase="${MVN_GPG_KEYS_GPGPASSPHRASE}"

echo "=== Release ${RELEASE_VERSION} published successfully! ==="
