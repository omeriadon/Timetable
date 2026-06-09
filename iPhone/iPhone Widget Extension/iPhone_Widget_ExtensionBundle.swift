//
//  iPhone_Widget_ExtensionBundle.swift
//  iPhone Widget Extension
//
//  Created by Adon Omeri on 14/5/2026.
//

import WidgetKit
import SwiftUI

@main
struct iPhone_Widget_ExtensionBundle: WidgetBundle {
    var body: some Widget {
        iPhone_Widget_Extension()
        iPhone_Widget_ExtensionLiveActivity()
    }
}
