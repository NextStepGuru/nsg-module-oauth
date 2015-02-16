This oauth module will allow you to access oauth v1 and v1.0a currently. I'm working on a v2 support as well.

Here is an example handler that will inject the module service and handle login to twitter

component {

	property name="oauthService" inject="oauthV1Service@oauth";

	function index(event,rc,prc){
		var data = getSetting('twitter')['oauth'];

		if(!structKeyExists(session,'twitterOAuth')){
			session['twitterOAuth'] = structNew();
		}

		if( event.getValue('id','doNothing') == 'activateUser' ){
			var results = duplicate(session['twitterOAuth']);
				results['socialserviceID'] = 8;
				results = renameField('oauth_token','accessToken',results);
				results = renameField('oauth_token_secret','clientSecret',results);
				results = renameField('user_id','referenceID',results);

			oauthService.init();
			oauthService.setRequestMethod('GET');
			oauthService.setConsumerKey(data['key']);
			oauthService.setConsumerSecret(data['secret']);
			oauthService.setAccessToken(session['twitterOAuth']['oauth_token']);
			oauthService.setAccessTokenSecret(session['twitterOAuth']['oauth_token_secret']);
			oauthService.setRequestURL('https://api.twitter.com/1.1/users/show.json');
			oauthService.addParam(name="user_id",value=results['referenceID']);
			var data = deserializeJSON(oauthService.send()['fileContent']);

			announceInterception( state='socialLoginSuccess', interceptData=results );

			location(url="/",addToken=false);

		}else if( event.valueExists('oauth_token') ){
			session['twitterOAuth']['oauth_token'] = event.getValue('oauth_token');
			session['twitterOAuth']['oauth_verifier'] = event.getValue('oauth_verifier');

			oauthService.init();
			oauthService.setConsumerKey(data['key']);
			oauthService.setConsumerSecret(data['secret']);
			oauthService.setRequestURL('https://api.twitter.com/oauth/access_token');
			oauthService.setRequestMethod('POST');
			oauthService.addParam(name="oauth_token",value=session['twitterOAuth']['oauth_token']);
			oauthService.addParam(name="oauth_verifier",value=session['twitterOAuth']['oauth_verifier']);

			var results = oauthService.send();

			var results = oauthService.send();
			if( results['status_code'] == 200 ){
				var myFields = listToArray(results['fileContent'],'&');

				for(var i=1;i<=arrayLen(myFields);i++){
					session['twitterOAuth'][listFirst(myFields[i],'=')] = listLast(myFields[i],'=');
				}
				setNextEvent('twitter/oauth/activateUser')
			}else{
				throw('Unknown OAuth Error');
			}

		}else{

			oauthService.init();
			oauthService.setConsumerKey(data['key']);
			oauthService.setConsumerSecret(data['secret']);
			oauthService.setRequestURL('https://api.twitter.com/oauth/request_token');
			oauthService.setRequestMethod('POST');

			oauthService.addParam(name="oauth_callback",value="#( cgi.server_port == 443 ? 'https' : 'http' )#://#cgi.http_host#/#event.getCurrentModule()#/oauth/");

			var results = oauthService.send();

			if( results['status_code'] == 200 ){
				var myFields = listToArray(results['fileContent'],'&');

				for(var i=1;i<=arrayLen(myFields);i++){
					session['twitterOAuth'][listFirst(myFields[i],'=')] = listLast(myFields[i],'=');
				}

				location(url="https://api.twitter.com/oauth/authorize?oauth_token=#session['twitterOAuth']['oauth_token']#",addToken=false);
			}else{
				throw('Unknown OAuth Error');
			}
		}
	}

}

Changelog

v1.0.0 - current release
Upcoming changes will include support for oauth V2 and additional modules for twitter, facebook, linkedin, pinterest, google, evernote, & trello to provide complete social login support.