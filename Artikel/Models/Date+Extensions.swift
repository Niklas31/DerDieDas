import Foundation

extension Date {
    var formattedRelative: String {
        let calendar = Calendar.current
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        formatter.locale = .current
        
        let startOfNow = calendar.startOfDay(for: Date())
        let startOfSelf = calendar.startOfDay(for: self)
        let components = calendar.dateComponents([.day], from: startOfSelf, to: startOfNow)
        
        var relativeComponents = DateComponents()
        relativeComponents.day = -(components.day ?? 0)
        return formatter.localizedString(from: relativeComponents)
    }
}
