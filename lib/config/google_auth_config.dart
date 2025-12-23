/// Google Authentication Configuration
/// 
/// IMPORTANT: This file contains the Google OAuth Client IDs.
/// 
/// For Google Sign-In to work properly:
/// 1. Flutter app MUST use the WEB Client ID (client_type: 3) as serverClientId
/// 2. Server MUST use the same WEB Client ID to verify tokens
/// 
/// From your google-services.json:
/// - Android Client ID (client_type: 1): 136483005746-qhh7kl05ssrfg928e8f5nt5qqijmb89i.apps.googleusercontent.com
/// - Web Client ID (client_type: 3): 136483005746-on8mm0vh6otio3ev71ntekemoaqblous.apps.googleusercontent.com
/// 
/// WHY WEB CLIENT ID?
/// - Android Client ID tokens can only be verified by Google's Android SDK
/// - Web Client ID tokens can be verified by any server using google-auth-library
/// - Using Web Client ID allows the Node.js backend to verify the token
class GoogleAuthConfig {
  /// Web Client ID - MUST match the server's googleClientId
  /// This is the client_id with client_type: 3 from google-services.json
  static const String webClientId = '136483005746-on8mm0vh6otio3ev71ntekemoaqblous.apps.googleusercontent.com';
  
  /// Android Client ID - Used automatically by Google Sign-In SDK
  /// This is the client_id with client_type: 1 from google-services.json
  static const String androidClientId = '136483005746-qhh7kl05ssrfg928e8f5nt5qqijmb89i.apps.googleusercontent.com';
  
  /// Project Number from google-services.json
  static const String projectNumber = '136483005746';
  
  /// Project ID from google-services.json
  static const String projectId = 'financenotes-11ff0';
  
  /// Scopes requested during Google Sign-In
  static const List<String> scopes = ['email', 'profile'];
  
  /// Verify that the configuration is correct
  /// Returns true if webClientId is set and not empty
  static bool get isValid => webClientId.isNotEmpty;
}

