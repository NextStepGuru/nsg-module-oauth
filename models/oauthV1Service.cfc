component name="oauthV1Service" accessors="true" singleton {

	property name="consumerKey";
	property name="consumerSecret";

	property name="OAuthToken" default="";
	property name="OAuthSecret" default="";

	property name="requestURL";
	property name="requestMethod" default="POST";

	property name="nonce";
	property name="timestamp";
	property name="version" default="1.0";
	property name="signature";
	property name="signatureMethod" default="HMAC-SHA1";

	property name="params";

	public any function init(){
		setParams(arrayNew());
		setTimestamp(createTimestamp());
		setNonce(createNonce());

		return this;
	}

	public any function send(){
		// creates the signature based on data;
		setSignature(createSignature());

		var httpService = new http();
			httpService.setURL(getRequestURL());
			httpService.setMethod(getRequestMethod());
			httpService.addParam(type='header',name='Authorization',value=getOAuthAuthorizationSignature());
			httpService.addParam(type='header',name='Accept',value="*/*");

		if( getRequestMethod() == 'POST' ){
			httpService.addParam(type='header',name='Content-Type',value="application/x-www-form-urlencoded");
		}

		for(var i=1;i<=arrayLen(getParams());i++){
			httpService.addParam(type=( getRequestMethod() == 'POST' ? 'formfield' : 'url' ), name=getParams()[i]['name'], value=getParams()[i]['value']);
		}

		return httpService.send().getPrefix();
	}

	public any function addParam(required string name,required string value){

		params.append({'name':arguments.name,'value':arguments.value});
	}

	public string function createSignature(){

		return hmacSha1(signKey=getConsumerSecret() & '&' & getOAuthSecret(),signMessage=getSignatureBaseString());
	}

	private string function getSignatureBaseString(){
		var buffer = createObject('java','java.lang.StringBuffer').init('');
		var mySignatureArray = arrayNew();

		buffer.append(getRequestMethod() & "&");
		buffer.append(encodeURL(getRequestURL()) & "&");

		mySignatureArray.append('oauth_consumer_key=' & getConsumerKey());
		mySignatureArray.append('oauth_nonce=' & getNonce());
		mySignatureArray.append('oauth_timestamp=' & getTimestamp() );
		mySignatureArray.append('oauth_version=' & getVersion() );
		mySignatureArray.append('oauth_signature_method=' & getSignatureMethod() );

		if( len(getOAuthToken()) ){
			mySignatureArray.append('oauth_token=' & getOAuthToken() );
		}

		for(var i=1;i<=arrayLen(getParams());i++){
			mySignatureArray.append( getParams()[i]['name'] & '=' & encodeURL(getParams()[i]['value']));
		}

		mySignatureArray.sort('textNoCase');

		buffer.append( encodeURL(arrayToList(mySignatureArray,'&')) );

		return buffer.toString();
	}

	private string function getOAuthAuthorizationSignature(){
		var buffer = createObject('java','java.lang.StringBuffer').init('');
		var myAuth = arrayNew();

		myAuth.append('oauth_consumer_key="' & encodeURL(getConsumerKey()) & '"' );
		myAuth.append('oauth_nonce="' & encodeURL(getNonce()) & '"' );
		myAuth.append('oauth_timestamp="' & encodeURL(getTimestamp()) & '"' );
		myAuth.append('oauth_version="' & encodeURL(getVersion()) & '"' );
		myAuth.append('oauth_signature_method="' & encodeURL(getSignatureMethod()) & '"' );
		myAuth.append('oauth_signature="' & encodeURL(getSignature()) & '"' );
		if( len(getOAuthToken()) ){
			myAuth.append('oauth_token="' & getOAuthToken() & '"' );
		}
		myAuth.sort('textNoCase');

		buffer.append("OAuth " & arrayToList(myAuth,', '));

		return buffer.toString();
	}

	private function createTimestamp(){

		return dateDiff('s',createDateTime(1970,1,1,0,0,0),now());
	}

	private function createNonce(){

		return lcase(hash(randRange(1,999999999)));
	}

	private string function hmacSha1(signKey,signMessage){
		var jMsg = JavaCast("string",arguments.signMessage).getBytes("UTF-8");
		var jKey = JavaCast("string",arguments.signKey).getBytes("UTF-8");

		var key = createObject("java","javax.crypto.spec.SecretKeySpec");
		var mac = createObject("java","javax.crypto.Mac");

			key = key.init(jKey,"HmacSHA1");

			mac = mac.getInstance(key.getAlgorithm());
			mac.init(key);
			mac.update(jMsg);

		return binaryEncode(mac.doFinal(),'base64');
	}

	private function encodeURL(required string str){
		var data = urlEncodedFormat(arguments.str);
		data = replace(data,'%5F','_','all');
		data = replace(data,'%2E','.','all');
		data = replace(data,'%2D','-','all');
		data = replace(data,'+','%2B','all');

		return data;
	}

}