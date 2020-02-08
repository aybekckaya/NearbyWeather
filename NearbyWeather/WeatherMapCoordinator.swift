//
//  WeatherMapCoordinator.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 08.02.20.
//  Copyright © 2020 Erik Maximilian Martens. All rights reserved.
//

import UIKit

enum WeatherMapStep: StepProtocol {
  case initial
  case weatherDetails(identifier: Int?)
  case none
}

class WeatherMapCoordinator: Coordinator {
  
  // MARK: - Required Properties
  
  private static var root: UINavigationController = {
    let navigationController = UINavigationController()
    navigationController.navigationBar.backgroundColor = .white
    navigationController.navigationBar.barTintColor = .black
    navigationController.navigationBar.tintColor = .nearbyWeatherStandard
    return navigationController
  }()
  
  override var initialStep: StepProtocol {
    return WeatherMapStep.initial
  }
  
  override var associatedStepperIdentifier: String {
    return WeatherMapStep.identifier
  }
  
  // MARK: - Additional Properties
  
  private lazy var stepper: WeatherMapStepper = {
    WeatherMapStepper(coordinator: self, type: WeatherMapStep.self)
  }()
  
  // MARK: - Initialization
  
  init(parentCoordinator: Coordinator?) {
    super.init(
      rootViewController: Self.root,
      parentCoordinator: parentCoordinator,
      type: WeatherMapStep.self
    )
  }
  
  // MARK: - Navigation
  
  @objc override func didReceiveStep(_ notification: Notification) {
    super.didReceiveStep(notification, type: WeatherMapStep.self)
  }
  
  override func executeRoutingStep(_ step: StepProtocol, passNextChildCoordinatorTo coordinatorReceiver: @escaping (NextCoordinator) -> Void) {
    guard let step = step as? WeatherMapStep else { return }
    switch step {
    case .initial:
      summonWeatherMapController(passNextChildCoordinatorTo: coordinatorReceiver)
    case let .weatherDetails(identifier):
      summonWeatherDetailsController(weatherDetailIdentifier: identifier,
                                     passNextChildCoordinatorTo: coordinatorReceiver)
    case .none:
      break
    }
  }
}

private extension WeatherMapCoordinator {
  
  func summonWeatherMapController(passNextChildCoordinatorTo coordinatorReceiver: (NextCoordinator) -> Void) {
    let mapViewController = R.storyboard.weatherMap.nearbyLocationsMapViewController()!
    mapViewController.title = R.string.localizable.tab_weatherMap()
    mapViewController.stepper = stepper
    
    mapViewController.tabBarItem.selectedImage = R.image.tabbar_map_ios11()
    mapViewController.tabBarItem.image = R.image.tabbar_map_ios11()
    
    (rootViewController as? UINavigationController)?.setViewControllers([mapViewController], animated: false)
    
    coordinatorReceiver(.none)
  }
  
  func summonWeatherDetailsController(weatherDetailIdentifier: Int?, passNextChildCoordinatorTo coordinatorReceiver: @escaping (NextCoordinator) -> Void) {
    let weatherDetailCoordinator = WeatherDetailCoordinator(parentCoordinator: self, weatherDetailIdentifier: weatherDetailIdentifier)

    guard let nextRoot = weatherDetailCoordinator.rootViewController as? UINavigationController else { return }
    rootViewController.present(nextRoot, animated: true)
    
    coordinatorReceiver(.single(weatherDetailCoordinator))
  }
}
