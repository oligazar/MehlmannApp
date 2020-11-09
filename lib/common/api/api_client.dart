
class ApiClient {
// 	export const getFields = async () => {
// 	return get('/fields');
// 	};
//
// 	export const createComment = async (fieldId, text) => {
// 	return post(`/fields/${fieldId}/comments`, {
// 	text,
// 	})
// 	};
//
// 	export const setField = async (name, fieldIds) => {
// 	return post('/fields/set_fields', {
// 	name, fieldIds,
// 	})
// 	};
//
// 	export const getComments = async (fieldId) => {
// 	return get(`/fields/${fieldId}/comments`);
// 	};
//
// 	export const getGroups = async () => {
// 	return get(`/groups`);
// 	};
//

/// auth/sign_in
/// headers.map.uid - admin@mahlmann.com
/// headers.map.client - "token"
/// headers.map.expiry - timestamp (long)
/// headers.map.admin - true
/// 	export const loginPost = (email, password, onAuthentication) => {
// 	console.log('login....')
// 	return post('/auth/sign_in', {
// 	email, password,
// 	}, true)
// };
//
// export const loginGet = (uid, client, token, expiry) => {
// return get(`/auth/validate_token?uid=${uid}&client=${client}&access-token=${token}&expiry=${expiry}&token-type=Bearer&Content-Type=application/json&Accept=application/json`, true)
// };
//
// export const createAccount = (email, password) => {
// return post('/users', {
// user: { email, password },
// });
// };
}