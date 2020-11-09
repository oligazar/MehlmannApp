enum WrapperState {
	LOADING,
	SUCCESS,
	ERROR,
}

class ResponseWrapper<T> {
	final T data;
	final String error;
	final WrapperState state;
	
	const ResponseWrapper(
			this.state, {
				this.data,
				this.error,
			});
	
	bool get isLoading => this.state == WrapperState.LOADING;
	
	@override
	String toString() => "data: $data, \nerror: $error, \nstate: $state";
	
	ResponseWrapper<T> copyWith({
		WrapperState state,
		T data,
		String error,
	}) {
		return ResponseWrapper(
			state ?? this.state,
			data: data ?? this.data,
			error: error ?? this.error,
		);
	}
	
	const ResponseWrapper.loading({T data}): this(WrapperState.LOADING, data: data);
	const ResponseWrapper.success(T data): this(WrapperState.SUCCESS, data: data);
	const ResponseWrapper.error(String error, {T data}): this(WrapperState.ERROR, error: error, data: data);
}