//
//  CrownImage.swift
//  FamilyBook
//
//  Created by Татьяна Макеева on 25.08.2025.
//

import SwiftUI

public struct CrownImage: View {
    @Environment(PremiumService.self) private var premium
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
            .onChange(of: premium.isPremium) { _, isPremium in
                if isPremium {
                    animateGlow = false
                }
            }
    }
}

#Preview {
    CrownImage()
        .environment(PremiumService(
            productIDs: [],
            storage: KeyValueStorageMock(objects: [
                "subscription": try! JSONEncoder().encode(PremiumStatus(isLifetime: false)),
            ]),
            storageKey: "subscription"
        ))
}
