import SwiftUI
import UIKit
import Charts

struct ProgressRing: View {
    var progress: Double; var size: CGFloat = 150
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.10), lineWidth: 14)
            Circle().trim(from: 0, to: max(0.02, min(1, progress))).stroke(LinearGradient(colors:[WCTheme.red, WCTheme.gold], startPoint:.top, endPoint:.bottom), style: StrokeStyle(lineWidth:14, lineCap:.round)).rotationEffect(.degrees(-90)).animation(.easeOut(duration:0.6), value: progress)
            VStack { Text("\(Int(progress*100))%").font(.title.weight(.black)); Text("to goal").font(.caption).foregroundStyle(WCTheme.textSecondary) }
        }.frame(width:size, height:size).accessibilityElement(children:.ignore).accessibilityLabel("Progress to goal, \(Int(progress*100)) percent")
    }
}
struct MacroBar: View { var label:String; var value:Double; var target:Double; var color:Color
    var body: some View { VStack(alignment:.leading, spacing:4){ HStack{ Text(label).font(.caption.weight(.bold)); Spacer(); Text("\(Int(value)) / \(Int(target)) g").font(.caption).foregroundStyle(WCTheme.textSecondary)}; ProgressView(value:min(1,target>0 ? value/target : 0)).tint(color) } }
}
struct SafetyBanner: View { var assessment: SafetyAssessment
    var body: some View { HStack(alignment:.top, spacing:10){ Image(systemName: assessment.isSafe ? "shield.checkered" : "exclamationmark.triangle.fill").foregroundStyle(assessment.isSafe ? WCTheme.success : WCTheme.warning); Text(assessment.message).font(.subheadline) }.wcCard() }
}
struct EmptyState: View { var icon:String; var title:String; var message:String
    var body: some View { VStack(spacing:10){ Image(systemName:icon).font(.largeTitle).foregroundStyle(WCTheme.gold); Text(title).fontWeight(.bold); Text(message).font(.subheadline).foregroundStyle(WCTheme.textSecondary).multilineTextAlignment(.center) }.padding().wcCard() }
}
struct DisclaimerView: View { var body: some View { Text("Disclaimer: WrestleCut is for educational guidance only and is not medical advice. Weight cutting carries risks. Consult your coach, athletic trainer, and doctor — especially if you are under 18, have any medical condition, or feel dizzy, faint, or ill. Stop and seek help if you have warning signs.").font(.caption).foregroundStyle(WCTheme.textTertiary).padding() } }


/// The decimal pad has no return key, so every number field in the app gets an explicit way out:
/// a gold "Done" bar above the keyboard, automatic dismissal on step/page changes, and scroll-to-dismiss.
enum KeyboardDismiss {
    static func now() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct KeyboardDoneModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { KeyboardDismiss.now() }.font(.body.weight(.black)).foregroundStyle(WCTheme.gold)
            }
        }
    }
}

extension View {
    func keyboardDoneBar() -> some View { modifier(KeyboardDoneModifier()) }
}
