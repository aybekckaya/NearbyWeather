//
//  BadgeService.swift
//  NearbyWeather
//
//  Created by Lukas Prokein on 20/10/2018.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import UIKit
import UserNotifications

final class BadgeService {
    
    // MARK: - Types
    
    private enum TemperatureSign {
        case plus
        case minus
    }
    
    private struct TemperatureSignNotificationBundle {
        let sign: TemperatureSign
        let city: String
    }
    
    // MARK: - Properties

    public static var shared: BadgeService!
    
    // MARK: - Methods
    
    public func areBadgesEnabled(with completion: @escaping (Bool) -> ()) {
        guard UserDefaults.standard.bool(forKey: kShowTemperatureOnAppIconKey) else {
            completion(false)
            return
        }
        PermissionsManager.shared.requestNotificationPermissions(with: completion)
    }
    
    public static func instantiateSharedInstance() {
        shared = BadgeService()
        
        if UserDefaults.standard.bool(forKey: kShowTemperatureOnAppIconKey) {
            shared.setBackgroundFetch(enabled: true)
        }
    }
    
    public func setBadgeService(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: kShowTemperatureOnAppIconKey)
        BadgeService.shared.updateBadge(withCompletionHandler: nil)
    }
    
    public func updateBadge(withCompletionHandler completionHandler: (() -> ())?) {
        guard UserDefaults.standard.bool(forKey: kShowTemperatureOnAppIconKey) else {
            clearAppIcon()
            completionHandler?()
            return
        }
        PermissionsManager.shared.requestNotificationPermissions { [weak self] approved in
            guard approved else {
                self?.clearAppIcon()
                return
            }
            self?.performBadgeUpdate()
            completionHandler?()
        }
    }
    
    public func performBackgroundBadgeUpdate(withCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        WeatherDataManager.shared.updateBookmarks { result in
            switch result {
            case .success:
                completionHandler(.newData)
            case .failure:
                completionHandler(.failed)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func performBadgeUpdate() {
        guard let weatherData = WeatherDataManager.shared.preferredBookmarkData else {
            clearAppIcon()
            return
        }
        
        let temperatureUnit = PreferencesManager.shared.temperatureUnit
        let temperatureKelvin = weatherData.atmosphericInformation.temperatureKelvin
        guard let temperature = ConversionService.temperatureIntValue(forTemperatureUnit: temperatureUnit, fromRawTemperature: temperatureKelvin) else { return }
        let lastTemperature = UIApplication.shared.applicationIconBadgeNumber
        UIApplication.shared.applicationIconBadgeNumber = abs(temperature)
        if lastTemperature < 0 && temperature > 0 {
            sendTemperatureSignChangeNotification(bundle: TemperatureSignNotificationBundle(sign: .plus, city: weatherData.cityName))
        } else if lastTemperature > 0 && temperature < 0 {
            sendTemperatureSignChangeNotification(bundle: TemperatureSignNotificationBundle(sign: .minus, city: weatherData.cityName))
        }
    }
    
    private func clearAppIcon() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    private func sendTemperatureSignChangeNotification(bundle: TemperatureSignNotificationBundle) {
        if #available(iOS 10, *) {
            let content = UNMutableNotificationContent()
            content.title = R.string.localizable.app_icon_temperature_sing_updated()
            switch bundle.sign {
            case .plus:
                content.body = R.string.localizable.temperature_above_zero(bundle.city)
            case .minus:
                content.body = R.string.localizable.temperature_below_zero(bundle.city)
            }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
            let request = UNNotificationRequest(identifier: "TemperatureSignNotification", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        } else {
            let localNotification = UILocalNotification()
            localNotification.fireDate = Date(timeIntervalSinceNow: 2.0)
            localNotification.alertTitle = R.string.localizable.app_icon_temperature_sing_updated()
            switch bundle.sign {
            case .plus:
                localNotification.alertBody = R.string.localizable.temperature_above_zero(bundle.city)
            case .minus:
                localNotification.alertBody = R.string.localizable.temperature_below_zero(bundle.city)
            }
            localNotification.timeZone = TimeZone.current
            
            UIApplication.shared.scheduleLocalNotification(localNotification)
        }
    }
    
    private func setBackgroundFetch(enabled: Bool) {
        guard enabled else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
            return
        }
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
    }
}
