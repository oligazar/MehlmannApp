
class LoginResponse {
	String token;
	String email;
	int expiry;
	bool admin;
	String version;
	
	LoginResponse({
		this.token,
		this.email,
		this.expiry,
		this.admin,
		this.version,
	});
	
	@override
	String toString() {
		return "token: $token, uid: $email, expiry: $expiry, admin: $admin, version: $version";
	}
}