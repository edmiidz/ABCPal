//
//  ActivityViewController.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 3/12/26.
//

import SwiftUI
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    @Binding var isPresented: Bool

    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil, isPresented: Binding<Bool>) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self._isPresented = isPresented
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Only present if we should be showing and nothing is already presented
        if isPresented && uiViewController.presentedViewController == nil {
            let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                isPresented = false
            }

            // For iPad popover support
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = uiViewController.view
                popover.sourceRect = CGRect(x: uiViewController.view.bounds.midX, y: uiViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            uiViewController.present(activityVC, animated: true)
        }
    }
}
