//
//  ContentView.swift
//  ReminderApp
//
//  Created by Han on 1/9/21.
//

import SwiftUI
import UserNotifications
import CoreLocation

class AppState: ObservableObject {
    static let shared = AppState()
    @Published var pageToNavigationTo : String?
}

class NotificationDelegate : NSObject, ObservableObject, UNUserNotificationCenterDelegate{
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge,.banner,.sound])
    }
    
    //listen actions
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            print("app opened from PushNotification tap")
            UIApplication.shared.applicationIconBadgeNumber = 0
          completionHandler()
        }
}

class NotificationManager{
    static let instance = NotificationManager()
    
    func checkPermissionGrant() {
        print("is loaded")
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if(settings.authorizationStatus == .authorized){
                print("granted")
                center.getPendingNotificationRequests { (notifications) in
                        print("Count: \(notifications.count)")
                        for item in notifications {
                            print(item.content.subtitle)
                        }
                    if(notifications.count == 0){
                        self.scheduleNotification()
                    }
                }
                
            }else{
                self.reqAuthorization()
                self.scheduleNotification()
            }
        }
       // return isScheduled
    }
    
    func reqAuthorization(){
        let options: UNAuthorizationOptions = [.alert,.sound,.badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) {(success, error) in
            if let error = error{
                print("Error: \(error)")
            }else {
                print("Success")
            }
        }
    }
    
    func scheduleNotification(){
        print("scheduled")
        let content = UNMutableNotificationContent()
        content.title = "This is first Noti"
        content.subtitle = "This is cool"
        content.sound = .default
        content.badge = 1
        
        //by time interval
        let triggerTime = UNTimeIntervalNotificationTrigger(timeInterval: 5.0, repeats: false)
        
        //by calendar
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 0
        dateComponents.weekday = 5
        let triggerDate = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        //by location
        let open = UNNotificationAction(identifier: "open", title: "Open", options: .foreground)
        
        let cancel = UNNotificationAction(identifier: "cancel", title: "Cancel", options: .destructive)
        
        let categories = UNNotificationCategory(identifier: "action", actions: [open,cancel], intentIdentifiers: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([categories])
        content.categoryIdentifier = "action"
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: triggerTime)
        UNUserNotificationCenter.current().add(request)
        
        
    }
    
}

struct ContentView: View {
    @ObservedObject var appState = AppState.shared //<-- note this
    @StateObject var delegate = NotificationDelegate()
    @State var navigate = "https://www.apple.com/sg/"
    
    var pushNavigationBinding : Binding<Bool> {
            .init { () -> Bool in
                appState.pageToNavigationTo != nil
            } set: { (newValue) in
                if !newValue { appState.pageToNavigationTo = nil }
            }
        }
    
    var body: some View {
        NavigationView {
                    VStack {
                        
                        SwiftUIWebView(url: URL(string: navigate ))
                            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification), perform: { _ in
                                navigate = "https://www.apple.com/sg/watch/"
                                
                            })
                    }
                }
       // VStack(spacing:40) {
            
           // if(UIApplication.shared.applicationState == .inactive){
            //    SwiftUIWebView(url: URL(string: //"https://www.apple.com/sg/apple-watch-hermes/"))
           // }else{
           //     SwiftUIWebView(url: URL(string: "https://www.apple.com/sg/"))
          //  }
           
            
            //Button("Request Permission") {
                // first request noti permission
                //NotificationManager.instance.reqAuthorization()
            //}

            //Button("Schedule Notification") {
                // second schedule noti
                //NotificationManager.instance.scheduleNotification()
                
            //}
       // }
        
        .onAppear{
            UNUserNotificationCenter.current().delegate = delegate
            NotificationManager.instance.checkPermissionGrant()
            //clear badge number
            UIApplication.shared.applicationIconBadgeNumber = 0
            //print(UIApplication.shared.applicationState)
        }
       
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
