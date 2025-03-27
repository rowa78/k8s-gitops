<?php
   $CONFIG = array (
	'oidc_login_client_id' => 'nextcloud', // Client ID: Step 1
	'oidc_login_client_secret' => 'DzBpKvdJlR1Hgjz0Duuror7gXROVul2o', // Client Secret: Got to Clients -> Client -> Credentials
	'oidc_login_provider_url' => 'https://auth.rwcloud.org/auth/realms/rwcloud',
	'oidc_login_end_session_redirect' => true, // Keycloak 18+
	'oidc_login_logout_url' => 'https://auth.rwcloud.org/apps/oidc_login/oidc', // Keycloak 18+
	// 'oidc_login_logout_url' => 'https://keycloak.example.com/auth/realms/MY_REALM/protocol/openid-connect/logout?redirect_uri=https%3A%2F%2Fcloud.example.com%2F', // Keycloak <18
	'oidc_login_auto_redirect' => true,
	'oidc_login_redir_fallback' => true,
	'oidc_login_attributes' => array(
		'id' => 'preferred_username',
		'mail' => 'email',
	),
	// If you are running Nextcloud behind a reverse proxy, make sure this is set
	'overwriteprotocol' => 'https',
);