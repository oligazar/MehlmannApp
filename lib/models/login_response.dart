
class LoginResponse {
	String token;
	String email;
	int expiry;
	bool admin;
	
	LoginResponse({
		this.token,
		this.email,
		this.expiry,
		this.admin,
	});
	
	@override
	String toString() {
		return "token: $token, uid: $email, expiry: $expiry, admin: $admin";
	}
}