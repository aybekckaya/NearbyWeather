//
//  UITableView+RegisterCells.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 03.01.21.
//  Copyright © 2021 Erik Maximilian Martens. All rights reserved.
//

import UIKit.UITableView
import UIKit.UITableViewCell

extension UITableView {
  
  func registerCells<C: UITableViewCell>(_ cells: [C.Type]) where C: ReuseIdentifiable {
    cells.forEach { registerCell($0) }
  }
  
  func registerCell<C: UITableViewCell>(_ cell: C.Type) where C: ReuseIdentifiable {
    register(cell, forCellReuseIdentifier: cell.reuseIdentifier)
  }
}
