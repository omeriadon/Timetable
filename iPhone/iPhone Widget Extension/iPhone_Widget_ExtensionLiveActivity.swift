//
//  iPhone_Widget_ExtensionLiveActivity.swift
//  iPhone Widget Extension
//
//  Created by Adon Omeri on 14/5/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct iPhone_Widget_ExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: iPhone_Widget_ExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension iPhone_Widget_ExtensionAttributes {
    fileprivate static var preview: iPhone_Widget_ExtensionAttributes {
        iPhone_Widget_ExtensionAttributes(name: "World")
    }
}

extension iPhone_Widget_ExtensionAttributes.ContentState {
    fileprivate static var smiley: iPhone_Widget_ExtensionAttributes.ContentState {
        iPhone_Widget_ExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: iPhone_Widget_ExtensionAttributes.ContentState {
         iPhone_Widget_ExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: iPhone_Widget_ExtensionAttributes.preview) {
   iPhone_Widget_ExtensionLiveActivity()
} contentStates: {
    iPhone_Widget_ExtensionAttributes.ContentState.smiley
    iPhone_Widget_ExtensionAttributes.ContentState.starEyes
}
