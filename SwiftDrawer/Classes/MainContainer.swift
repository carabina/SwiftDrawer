//
//  MainContainer.swift
//  DrawerDemo
//
//  Created by Millman on 2019/6/27.
//  Copyright © 2019 Millman. All rights reserved.
//

import SwiftUI
struct MainContainer<Content: View> : View {
    @ObjectBinding private var drawerControl: DrawerControl
    @ObjectBinding private var leftRear: SliderStatus
    @ObjectBinding private var rightRear: SliderStatus
    
    @State private var gestureCurrent: Length = 0
    
    let main: AnyView
    private var maxMaskAlpha: Length
    private var maskEnable: Bool
    
    var body: some View {
        GeometryReader { proxy in
            self.generateBody(proxy: proxy)
        }.animation(.default)
        
    }
    
    init(content: Content,
         maxMaskAlpha: Length = 0.25,
         maskEnable: Bool = true,
         drawerControl: DrawerControl) {
        
        self.main = AnyView.init(content.environmentObject(drawerControl))
        self.maxMaskAlpha = maxMaskAlpha
        self.maskEnable = maskEnable
        self.drawerControl = drawerControl
        self.leftRear = drawerControl.status[.leftRear] ?? SliderStatus(type: .none)
        self.rightRear = drawerControl.status[.rightRear] ?? SliderStatus(type: .none)
    }
    
    func generateBody(proxy: GeometryProxy) -> some View {
        let haveRear = self.leftRear.type != .none || self.rightRear.type != .none
        let maxRadius = haveRear ? max(self.leftRear.shadowRadius, self.rightRear.shadowRadius) : 0
        let parentSize = proxy.size
        if haveRear {
            leftRear.parentSize = parentSize
            rightRear.parentSize = parentSize
        }
        
        return ZStack {
            self.main
            if maskEnable && drawerControl.maxShowRate > 0 {
                AnyView(Color.black.opacity(Double(drawerControl.maxShowRate*self.maxMaskAlpha)))
                    .tapAction {
                    self.drawerControl.hideAllSlider()
                }.padding(EdgeInsets(top: -proxy.safeAreaInsets.top, leading: 0, bottom: -proxy.safeAreaInsets.bottom, trailing: 0))
            }
        }
        .shadow(radius: maxRadius)
        .offset(x: self.offset, y: 0)
        .gesture(DragGesture().onChanged({ (value) in
            let will = self.offset + (value.translation.width-self.gestureCurrent)
            if self.leftRear.type != .none {
                let range = 0...self.leftRear.sliderWidth
                if range.contains(will) {
                    self.leftRear.currentStatus = .moving(offset: will)
                    self.gestureCurrent = value.translation.width
                }
            }
            
            if self.rightRear.type != .none {
                let range = (-self.rightRear.sliderWidth)...0
                if range.contains(will) {
                    self.rightRear.currentStatus = .moving(offset: will)
                    self.gestureCurrent = value.translation.width
                }
            }
        }).onEnded({ (value) in
            let will = self.offset + (value.translation.width-self.gestureCurrent)
            if self.leftRear.type != .none {
                let range = 0...self.leftRear.sliderWidth
                self.leftRear.currentStatus = will-range.lowerBound > range.upperBound-will ? .show : .hide
            }
            if self.rightRear.type != .none {
                let range = (-self.rightRear.sliderWidth)...0
                self.rightRear.currentStatus = will-range.lowerBound < range.upperBound-will ? .show : .hide
            }
            self.gestureCurrent = 0
        }))
    }
    
    var offset: Length {
        switch (self.leftRear.currentStatus, self.rightRear.currentStatus) {
        case (.hide, .hide):
            return 0
        case (.show, .hide):
            return self.leftRear.sliderOffset()
        case (.hide, .show):
            return self.rightRear.sliderOffset()
        default:
            if self.leftRear.currentStatus.isMoving {
                return self.leftRear.sliderOffset()
            } else if self.rightRear.currentStatus.isMoving {
                return self.rightRear.sliderOffset()
            }
        }
        return 0
    }
    
    var maxShowRate: Length {
        return max(self.leftRear.showRate, self.rightRear.showRate)
    }
}

#if DEBUG
struct MainContainer_Previews : PreviewProvider {
    static var previews: some View {
        self.generate()
    }
    
    static func generate() -> some View {
        let view = DemoSlider.init(type: .leftRear)
        let c = DrawerControl()
        c.setSlider(view: view)
        return MainContainer.init(content: DemoMain(), drawerControl: c)

    }

}
#endif
