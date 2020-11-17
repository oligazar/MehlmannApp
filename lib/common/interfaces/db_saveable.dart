abstract class DBSaveable {
	Map<String, dynamic> toMap();
	
	@override
	String toString() => this.toMap().toString();
}