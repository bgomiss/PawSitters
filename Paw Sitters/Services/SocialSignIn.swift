//
//  SocialSignIn.swift
//  Paw Sitters
//
//  "Continue with Apple" and "Continue with Google" for Firebase Auth.
//  Both return the signed-in user plus the name/email the provider shared,
//  so the app can create a profile the first time someone uses them.
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

struct SocialSignInResult {
    let user: User
    let name: String?
    let email: String?
}

enum SocialSignIn {
    // MARK: - Google

    @MainActor
    static func signInWithGoogle() async throws -> SocialSignInResult {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AppError.authError("Google sign-in isn't configured for this app yet.")
        }
        guard let presenter = topViewController() else {
            throw AppError.authError("Couldn't show the Google sign-in screen.")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AppError.authError("Google didn't return a sign-in token.")
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: result.user.accessToken.tokenString)
        let authResult = try await Auth.auth().signIn(with: credential)
        return SocialSignInResult(user: authResult.user,
                                  name: result.user.profile?.name,
                                  email: result.user.profile?.email)
    }

    // MARK: - Apple

    @MainActor
    static func signInWithApple() async throws -> SocialSignInResult {
        let nonce = randomNonce()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let coordinator = AppleSignInCoordinator()
        let appleCredential = try await coordinator.perform(request)
        guard let tokenData = appleCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            throw AppError.authError("Apple didn't return a sign-in token.")
        }
        let credential = OAuthProvider.appleCredential(withIDToken: idToken,
                                                       rawNonce: nonce,
                                                       fullName: appleCredential.fullName)
        let authResult = try await Auth.auth().signIn(with: credential)
        // Apple only shares the name on the very first sign-in.
        let name = appleCredential.fullName.map {
            PersonNameComponentsFormatter.localizedString(from: $0, style: .default)
        }
        return SocialSignInResult(user: authResult.user,
                                  name: (name?.isEmpty == false) ? name : authResult.user.displayName,
                                  email: appleCredential.email ?? authResult.user.email)
    }

    /// Whether the signed-in account uses Sign in with Apple.
    static var usesApple: Bool {
        Auth.auth().currentUser?.providerData.contains { $0.providerID == "apple.com" } ?? false
    }
    
    /// Revokes the app's Sign in with Apple tokens (required by Apple before an
    /// account is deleted). Asks the user to confirm with Apple once more to get
    /// a fresh authorization code, which Firebase exchanges and revokes.
    @MainActor
    static func revokeAppleToken() async throws {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = []
        let credential = try await AppleSignInCoordinator().perform(request)
        guard let codeData = credential.authorizationCode,
              let code = String(data: codeData, encoding: .utf8) else {
            throw AppError.authError("Apple didn't return an authorization code.")
        }
        try await Auth.auth().revokeToken(withAuthorizationCode: code)
    }
    
    /// Best effort: removes the app's access to the user's Google account
    /// (not required by Google, but the account is going away anyway).
    @MainActor
    static func disconnectGoogleIfNeeded() async {
        guard Auth.auth().currentUser?.providerData.contains(where: { $0.providerID == "google.com" }) == true else { return }
        if GIDSignIn.sharedInstance.currentUser == nil {
            _ = try? await GIDSignIn.sharedInstance.restorePreviousSignIn()
        }
        try? await GIDSignIn.sharedInstance.disconnect()
    }
    
    /// True when the user backed out of the provider's sheet (not an error to show).
    static func isCancellation(_ error: Error) -> Bool {
        if let error = error as? ASAuthorizationError, error.code == .canceled { return true }
        let nsError = error as NSError
        return nsError.domain == kGIDSignInErrorDomain && nsError.code == GIDSignInError.canceled.rawValue
    }

    static func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    // MARK: - Helpers

    @MainActor
    private static func topViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        var top = root
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        precondition(SecRandomCopyBytes(kSecRandomDefault, length, &bytes) == errSecSuccess)
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

/// Bridges Sign in with Apple's delegate API to async/await.
private final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate,
                                            ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    @MainActor
    func perform(_ request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation?.resume(returning: credential)
        } else {
            continuation?.resume(throwing: AppError.authError("Unexpected Apple credential."))
        }
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? ASPresentationAnchor()
    }
}
