class LoginResponse {
	String id;
	String email;
	String name;
	String token;
	String lastLogin;
	String uuid;
	List<String> roles;
	
	LoginResponse({
		this.id,
		this.email,
		this.name,
		this.token,
		this.lastLogin,
		this.uuid,
		this.roles,
	});
	
	LoginResponse.fromJson(Map<String, dynamic> json) {
		this.id = json["id"];
		this.email = json["email"];
		this.name = json["name"];
		this.token = json["token"];
		this.lastLogin = json["last_login"];
		this.uuid = json["uuid"];
		this.roles = List<String>.from(json["roles"]);
	}
	
	@override
	String toString() {
		return "id: $id, email: $email, name: $name, token: $token, lastLogin: $lastLogin, uuid: $uuid, roles: $roles";
	}
	
	Map<String, dynamic> toFb() => {
		"id": this.id,
		"email": this.email,
		"name": this.name,
		"token": this.token,
		"last_login": this.lastLogin,
	};
}