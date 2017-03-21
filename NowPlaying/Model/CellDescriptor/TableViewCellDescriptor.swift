//
//  TableViewCellDescriptor.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/21/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

struct TableViewCellDescriptor {
	let reuseIdentifier: String
	let configure: (UITableViewCell, IndexPath) -> Void
	let register: (UITableView) -> Void
	
	init<Cell: UITableViewCell>(reuseIdentifier: String, configure: @escaping (Cell, IndexPath) -> Void) {
		self.reuseIdentifier = reuseIdentifier
		self.configure = { cell, indexPath in
			configure(cell as! Cell, indexPath) // swiftlint:disable:this force_cast
		}
		self.register = { tableView in
			tableView.register(Cell.self, forCellReuseIdentifier: reuseIdentifier)
		}
	}
	
	init<Cell: UITableViewCell>(configure: @escaping (Cell, IndexPath) -> Void) where Cell: NibReusable {
		self.reuseIdentifier = Cell.reuseIdentifier
		self.configure = { cell, indexPath in
			configure(cell as! Cell, indexPath) // swiftlint:disable:this force_cast
		}
		self.register = { tableView in
			tableView.register(cellType: Cell.self)
		}
	}
	
}
