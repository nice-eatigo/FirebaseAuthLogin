//
//  FirebaseAPIService.swift
//  Consumer
//
//  Created by kilovata on 16/03/2018.
//  Copyright © 2018 Eatigo. All rights reserved.
//

import Firebase

protocol IFirebaseAPIService {
    
    var isExistFirebaseUser: Bool { get }
    var isLinkedUser: Bool { get }
    var firebasePushToken: String? { get }

    func createUser(email: String, password: String, name: String, completion: @escaping (String?, Error?) -> Void)
    func login(email: String, password: String, completion: @escaping (String?, Error?) -> Void)
    
    //func loginFacebook(completion: @escaping (String?, Error?) -> Void)
    
    func pendingCredential(response: Error?, completion: @escaping (String?, String?, Error?) -> Void)
    func login(with token: String, completion: @escaping (String?, Error?) -> Void)
    func anonymousLogin(completion: @escaping (FirebaseAuth.User?, Error?) -> Void)
    func linkUser(token: String, completion: @escaping (Bool, Error?) -> Void)
    func updateToken(completion: @escaping (String?, Error?) -> Void)
    func forgotPassword(email: String, completion: @escaping (Bool, Error?) -> Void)
    func logout(completion: @escaping (Bool, Error?) -> Void)
    func isAccountExistsWithDifferentCredential(error: Error?) -> Bool
}

struct FirebaseAPIService: IFirebaseAPIService {
    
    var isExistFirebaseUser: Bool {
        return Auth.auth().currentUser != nil
    }
    
    var isLinkedUser: Bool {
        
        var value = false
        if let user = Auth.auth().currentUser {
            user.providerData.forEach { info in
                if info.providerID.contains("facebook.com") {
                    value = true
                }
            }
        }
        
        return value
    }
    
    func updateToken(completion: @escaping (String?, Error?) -> Void) {
        
        if let user = Auth.auth().currentUser {
            user.getIDTokenForcingRefresh(true) { (token, error) in
                completion(token, error)
            }
        } else {
            completion(nil, nil)
        }
    }
    
    func getIDToken(user: FirebaseAuth.User, completion: @escaping (String?, Error?) -> Void) {
        
        user.getIDToken { token, error in
            completion(token, error)
        }
    }
    
    func createUser(email: String, password: String, name: String, completion: @escaping (String?, Error?) -> Void) {
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            
            if let firebaseUser = authResult?.user {
                firebaseUser.getIDToken { token, error in
                    
                    if let _ = token {
                        let profileChangeRequest = firebaseUser.createProfileChangeRequest()
                        profileChangeRequest.displayName = name
                        profileChangeRequest.commitChanges(completion: { (profileChangeRequestError) in
                            completion(token, error)
                        })
                    } else {
                        completion(nil, error)
                    }
                }
            } else {
                completion(nil, error)
            }
        }
    }
    
    func login(email: String, password: String, completion: @escaping (String?, Error?) -> Void) {
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        login(credential: credential, completion: completion)
    }
    
    /*
    func loginFacebook(completion: @escaping (String?, Error?) -> Void) {
        
        FacebookConnect().logIn { (token, error) in
            
            if let token = token {
                let credential = FacebookAuthProvider.credential(withAccessToken: token)
                self.login(credential: credential, completion: completion)
            } else {
                completion(nil, error)
            }bra
        }
    }
    */
    
    private func login(credential: AuthCredential, completion: @escaping (String?, Error?) -> Void) {
        
        Auth.auth().signIn(with: credential) { (user, error) in
            if let firebaseUser = user {
                firebaseUser.getIDToken { firebaseToken, error in
                    completion(firebaseToken, error)
                }
            } else {
                guard let error = error else {
                    completion(nil, nil)
                    return
                }
                
                if let errorCode = AuthErrorCode(rawValue: error._code) {
                    let localizeError = self.localizeError(error: error, code: errorCode)
                    completion(nil, localizeError)
                } else {
                    completion(nil, error)
                }
            }
        }
    }
    
    func pendingCredential(response: Error?, completion: @escaping (String?, String?, Error?) -> Void) {
        /*
        guard let userInfo = response?._userInfo as? [String: Any]
            , let existingEmail = userInfo[AuthErrorUserInfoEmailKey] as? String else {
                completion(nil, nil, response)
                return
        }
        
        Auth.auth().fetchSignInMethods(forEmail: existingEmail) { methods, error in
            let emailCredentialMethod = "password"
            let hasUsedEmailCredentialBeforeFacebookCredential = methods?.first == emailCredentialMethod
            if hasUsedEmailCredentialBeforeFacebookCredential {
                guard let pendingCredential = FacebookConnect.currentAccessToken() else {
                    return
                }
                
                completion(existingEmail, pendingCredential, error)
            }
        }
         */
    }
    
    func login(with token: String, completion: @escaping (String?, Error?) -> Void) {
        
        Auth.auth().signIn(withCustomToken: token) { (authResult, error) in
            
            if let firebaseUser = authResult?.user {
                firebaseUser.getIDToken { firebaseToken, error in
                    completion(firebaseToken, error)
                }
            } else {
                completion(nil, error)
            }
        }
    }
    
    func anonymousLogin(completion: @escaping (FirebaseAuth.User?, Error?) -> Void) {
        
        Auth.auth().signInAnonymously { authResult, error in
            completion(authResult?.user, error)
        }
    }
    
    func linkUser(token: String, completion: @escaping (Bool, Error?) -> Void) {
        
        let credential = FacebookAuthProvider.credential(withAccessToken: token)
        if let firebaseUser = Auth.auth().currentUser {
            firebaseUser.link(with: credential) { (user, error) in
                completion(user != nil, error)
            }
        } else {
            completion(false, nil)
        }
    }
    
    func forgotPassword(email: String, completion: @escaping (Bool, Error?) -> Void) {
        
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            guard let _ = error else {
                return completion(true, nil)
            }
            completion(false, error)
        }
    }
    
    func logout(completion: @escaping (Bool, Error?) -> Void) {
        
        do {
            try Auth.auth().signOut()
            completion(true, nil)
        } catch {
            print(error)
            completion(false, error)
        }
    }
    
    var firebasePushToken: String? {
        return InstanceID.instanceID().token()
    }
    
    func isAccountExistsWithDifferentCredential(error: Error?) -> Bool {
        if let firError = error {
            let code = firError._code
            let authErrorCode = AuthErrorCode(rawValue: code)
            if authErrorCode == AuthErrorCode.accountExistsWithDifferentCredential {
                return true
            }
        }
        
        return false
    }
    
    private func localizeError(error: Error?, code: AuthErrorCode) -> NSError {
        let localizeKey = self.localizeKey(code: code)
        if let error = error as NSError? {
            var userInfo = error.userInfo
            userInfo[NSLocalizedDescriptionKey] = LS("\(localizeKey)")
            let localizeError = NSError(domain: error.domain, code: error.code, userInfo: userInfo)
            return localizeError
        } else {
            let localizeError = NSError(domain: "", code: code.rawValue, userInfo: [NSLocalizedDescriptionKey : LS("\(localizeKey)")])
            return localizeError
        }
    }
    
    private func localizeKey(code: AuthErrorCode) -> String {
        let errorCodeMapping: [AuthErrorCode: String] = [
            .accountExistsWithDifferentCredential: "ERROR_ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL"
            , .credentialAlreadyInUse: "ERROR_CREDENTIAL_ALREADY_IN_USE"
            , .customTokenMismatch: "ERROR_CUSTOM_TOKEN_MISMATCH"
            , .emailAlreadyInUse: "ERROR_EMAIL_ALREADY_IN_USE"
            , .invalidCredential: "ERROR_INVALID_CREDENTIAL"
            , .invalidCustomToken: "ERROR_INVALID_CUSTOM_TOKEN"
            , .invalidEmail: "ERROR_INVALID_EMAIL"
            , .invalidUserToken: "ERROR_INVALID_USER_TOKEN"
            , .operationNotAllowed: "ERROR_OPERATION_NOT_ALLOWED"
            , .requiresRecentLogin: "ERROR_REQUIRES_RECENT_LOGIN"
            , .userDisabled: "ERROR_USER_DISABLED"
            , .userMismatch: "ERROR_USER_MISMATCH"
            , .userNotFound: "ERROR_USER_NOT_FOUND"
            , .userTokenExpired: "ERROR_USER_TOKEN_EXPIRED"
            , .weakPassword: "ERROR_WEAK_PASSWORD"
            , .wrongPassword: "ERROR_WRONG_PASSWORD"
        ]
        
        let result = errorCodeMapping[code]
        return result ?? "common_error"
    }
}

func LS(_ string: String) -> String {
    return string
}
