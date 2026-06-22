//
//  CrownImage.swift
//  FamilyBook
//
//  Created by Татьяна Макеева on 25.08.2025.
//

import SwiftUI

public struct CrownImage: View {
    @EnvironmentObject var premium: PremiumService
    @State private var animateGlow = false
    
    public init() {}
    
    public var body: some View {
        Image(systemName: "crown.fill")
            .font(.title2)
            .foregroundColor(premium.isPremium ? .gray : .yellow)
            .shadow(color: animateGlow && !premium.isPremium ? .yellow.opacity(0.8) : .clear, radius: 8)
            .scaleEffect(animateGlow && !premium.isPremium ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateGlow)
            .onAppear {
                if !premium.isPremium {
                    animateGlow = true
                }
            }
            .onDisappear {
                animateGlow = false
            }
            .onChange(of: premium.isPremium) { isPremium in
                if isPremium {
                    animateGlow = false
                }
            }
    }
}

@available(iOS 17.0, *)
#Preview {
    CrownImage()
        .environmentObject(PremiumService(
            productIDs: [],
            storage: KeyValueStorageMock(objects: [
                "subscription": try! JSONEncoder().encode(PremiumStatus(isLifetime: false)),
            ]),
            storageKey: "subscription"
        ))
}
