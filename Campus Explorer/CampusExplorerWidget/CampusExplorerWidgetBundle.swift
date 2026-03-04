//
//  CampusExplorerWidgetBundle.swift
//  CampusExplorerWidget
//
//  Created by Y N Pragnesh on 05/02/26.
//

import WidgetKit
import SwiftUI

@main
@available(iOS 17.0, *)
struct CampusExplorerWidgetBundle: WidgetBundle {
    var body: some Widget {
        CampusExplorerWidget()
        CampusExplorerMediumWidget()
        CampusExplorerLargeWidget()
        CampusExplorerWidgetLiveActivity()
    }
}
