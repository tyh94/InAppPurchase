//
//  PremiumCrownModifier.swift
//  FamilyBook
//
//  Created by Татьяна Макеева on 25.08.2025.
//

import SwiftUI

extension View {
    public func premiumCrown(
        size: CGFloat = 16,
        offsetX: CGFloat = -8,
        offsetY: CGFloat = -8,
        rotation: Double = -35
    ) -> some View {
        self.modifier(
            PremiumCrownModifier(
                size: size,
                offsetX: offsetX,
                offsetY: offsetY,
                rotation: rotation
            )
        )
    }
}

private struct PremiumCrownModifier: ViewModifier {
    @Environment(PremiumService.self) private var premium
    var size: CGFloat
    var offsetX: CGFloat
    var offsetY: CGFloat
    var rotation: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topLeading) {
                if !premium.isPremium {
                    CrownImage()
                        .padding(size * 0.2)
                        .rotationEffect(.degrees(rotation))
                        .offset(x: offsetX, y: offsetY)
                        .frame(width: size, height: size)
                }
            }
    }
}

#Preview {
    Image(systemName: "mic.fill")
        .font(.title)
        .padding()
        .background(Circle().fill(.red))
        .foregroundColor(.white)
        .shadow(radius: 5)
        .premiumCrown()
        .environment(PremiumService(
            productIDs: [],
            storage: KeyValueStorageMock(objects: [
                "subscription": try! JSONEncoder().encode(PremiumStatus(isLifetime: false)),
            ]),
            storageKey: "subscription"
        ))
    
    Image(systemName: "mic.fill")
        .font(.title)
        .padding()
        .background(Circle().fill(.red))
        .foregroundColor(.white)
        .shadow(radius: 5)
        .premiumCrown(size: 20, offsetX: -10, offsetY: -10)
        .environment(PremiumService(
            productIDs: [],
            storage: KeyValueStorageMock(objects: [
                "subscription": try! JSONEncoder().encode(PremiumStatus(isLifetime: true)),
            ]),
            storageKey: "subscription"
        ))
}
