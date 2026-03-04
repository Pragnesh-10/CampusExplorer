//
//  CampusExplorerWidgetLiveActivity.swift
//  CampusExplorerWidget
//
//  Created by Y N Pragnesh on 05/02/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct CampusExplorerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

@available(iOS 16.1, *)
struct CampusExplorerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CampusExplorerWidgetAttributes.self) { context in
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
            .widgetURL(URL(string: "https://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

@available(iOS 16.1, *)
extension CampusExplorerWidgetAttributes {
    fileprivate static var preview: CampusExplorerWidgetAttributes {
        CampusExplorerWidgetAttributes(name: "World")
    }
}

@available(iOS 16.1, *)
extension CampusExplorerWidgetAttributes.ContentState {
    fileprivate static var smiley: CampusExplorerWidgetAttributes.ContentState {
        CampusExplorerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: CampusExplorerWidgetAttributes.ContentState {
         CampusExplorerWidgetAttributes.ContentState(emoji: "🤩")
     }
}
